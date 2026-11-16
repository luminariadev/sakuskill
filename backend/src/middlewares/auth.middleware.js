const jwt = require('jsonwebtoken');
const env = require('../config/env');
const db = require('../config/database');
const AppError = require('../utils/AppError');

const extractBearerToken = (req) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.split(' ')[1];
};

const verifyTokenAndSession = async (token) => {
  let decoded;
  try {
    decoded = jwt.verify(token, env.jwt.secret);
  } catch (err) {
    throw new AppError(
      'Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali.',
      401,
      'INVALID_OR_EXPIRED_TOKEN'
    );
  }

  // Cek apakah token sudah dicabut melalui logout (FR-06)
  if (decoded.jti) {
    const { rowCount } = await db.query(
      'SELECT 1 FROM revoked_tokens WHERE jti = $1 LIMIT 1',
      [decoded.jti]
    );
    if (rowCount > 0) {
      throw new AppError(
        'Sesi ini telah berakhir (logged out). Silakan login kembali.',
        401,
        'TOKEN_REVOKED'
      );
    }
  }

  // Ambil data pengguna terkini dari database
  const { rows } = await db.query(
    'SELECT user_id, nama, email, peran, status_verifikasi FROM users WHERE user_id = $1 LIMIT 1',
    [decoded.sub]
  );

  if (rows.length === 0) {
    throw new AppError('Akun pengguna tidak ditemukan.', 401, 'USER_NOT_FOUND');
  }

  const user = rows[0];
  return {
    ...user,
    jti: decoded.jti,
    exp: decoded.exp,
    capabilities: {
      can_buy_services: true,
      can_publish_gigs: true,
      is_admin: user.peran === 'Administrator',
    },
  };
};

// Wajib login untuk mengakses endpoint terproteksi (FR-04, NFR-07)
const authenticate = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      throw new AppError(
        'Akses ditolak. Token autentikasi (Bearer) wajib disertakan.',
        401,
        'UNAUTHORIZED'
      );
    }
    req.user = await verifyTokenAndSession(token);
    return next();
  } catch (error) {
    return next(error);
  }
};

// Opsional login (untuk melihat detail gig milik sendiri yang berstatus Nonaktif)
const optionalAuthenticate = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);
    if (token) {
      req.user = await verifyTokenAndSession(token);
    }
    return next();
  } catch (error) {
    return next();
  }
};

// Admin permission terpisah dari pengguna biasa (Kerjaan #3, FR-07, NFR-08)
const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.peran !== 'Administrator') {
    return next(
      new AppError(
        'Akses ditolak. Fungsi ini hanya dapat diakses oleh Administrator.',
        403,
        'ADMIN_PERMISSION_REQUIRED'
      )
    );
  }
  return next();
};

module.exports = {
  authenticate,
  optionalAuthenticate,
  requireAdmin,
};
