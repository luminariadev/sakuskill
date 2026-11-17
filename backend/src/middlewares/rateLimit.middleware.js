const rateLimit = require('express-rate-limit');

/**
 * Rate Limiter Global: Mencegah serangan DoS / flood request berlebihan (150 req / menit per IP).
 * Sesuai rekomendasi OWASP A04/A07 dan mitigasi DoS (Denial of Service).
 */
const globalRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 menit
  max: 150, // maksimal 150 request per IP dalam 1 menit
  standardHeaders: true, // Kirim RateLimit-* headers sesuai RFC
  legacyHeaders: false,
  skip: (req) => req.path.includes('/health'), // Abaikan health check
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: {
        code: 'TOO_MANY_REQUESTS',
        message: 'Terlalu banyak permintaan dari IP Anda. Silakan coba lagi setelah 1 menit.',
        details: { retry_after_seconds: 60 },
      },
    });
  },
});

/**
 * Rate Limiter Khusus Autentikasi (Login & Registrasi):
 * Mencegah Credential Stuffing, Dictionary Brute Force, dan Registrasi Bot massal (10 req / menit per IP).
 * Sesuai modul Access Attack & Password Cracking.
 */
const authRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 menit
  max: 12, // batas 12 percobaan per IP dalam 1 menit
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: {
        code: 'AUTH_RATE_LIMIT_EXCEEDED',
        message: 'Batas percobaan autentikasi terlampaui. Demi keamanan akun, silakan tunggu 1 menit sebelum mencoba lagi.',
        details: { retry_after_seconds: 60 },
      },
    });
  },
});

module.exports = {
  globalRateLimiter,
  authRateLimiter,
};
