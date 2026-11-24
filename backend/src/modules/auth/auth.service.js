const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const env = require('../../config/env');
const authRepository = require('./auth.repository');
const AppError = require('../../utils/AppError');

class AuthService {
  formatUserWithCapabilities(user) {
    return {
      user_id: user.user_id,
      nama: user.nama,
      email: user.email,
      peran: user.peran,
      status_verifikasi: user.status_verifikasi,
      deskripsi_profil: user.deskripsi_profil,
      foto_profil: user.foto_profil || null,
      foto_url: user.foto_profil || null,
      dibuat_pada: user.dibuat_pada,
      capabilities: {
        can_buy_services: true,
        can_publish_gigs: true,
        is_admin: user.peran === 'Administrator',
      },
    };
  }

  generateToken(user) {
    const jti = crypto.randomUUID();
    const payload = {
      sub: user.user_id,
      email: user.email,
      peran: user.peran,
      jti,
    };
    const token = jwt.sign(payload, env.jwt.secret, {
      expiresIn: env.jwt.expiresIn,
    });
    return { token, jti };
  }

  async register(payload) {
    const existingUser = await authRepository.findByEmail(payload.email);
    if (existingUser) {
      throw new AppError(
        'Alamat email sudah terdaftar. Silakan gunakan email lain atau login.',
        409,
        'EMAIL_ALREADY_EXISTS'
      );
    }

    // Hash kata sandi dengan bcrypt (NFR-05: dilarang menyimpan plaintext)
    const kataSandiHash = await bcrypt.hash(payload.kata_sandi, 10);

    const newUser = await authRepository.createUser({
      nama: payload.nama,
      email: payload.email,
      kataSandiHash,
      peran: payload.peran || 'Penyedia Jasa',
      deskripsiProfil: payload.deskripsi_profil,
    });

    await authRepository.writeAuditLog({
      aktorId: newUser.user_id,
      aksi: 'REGISTER_ACCOUNT',
      objekTipe: 'Users',
      objekId: newUser.user_id,
      statusSebelum: null,
      statusSesudah: newUser.status_verifikasi,
    });

    const { token } = this.generateToken(newUser);

    return {
      user: this.formatUserWithCapabilities(newUser),
      token,
    };
  }

  async login({ email, kata_sandi }) {
    const user = await authRepository.findByEmail(email);

    // FR-05: Tolak login tanpa mengungkapkan apakah email atau kata sandi yang salah
    if (!user) {
      throw new AppError(
        'Email atau kata sandi yang Anda masukkan tidak valid.',
        401,
        'INVALID_CREDENTIALS'
      );
    }

    const isPasswordValid = await bcrypt.compare(kata_sandi, user.kata_sandi_hash);
    if (!isPasswordValid) {
      throw new AppError(
        'Email atau kata sandi yang Anda masukkan tidak valid.',
        401,
        'INVALID_CREDENTIALS'
      );
    }

    const { token } = this.generateToken(user);

    return {
      user: this.formatUserWithCapabilities(user),
      token,
    };
  }

  async logout(userContext) {
    const expiresAt = userContext.exp
      ? new Date(userContext.exp * 1000)
      : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await authRepository.revokeToken({
      jti: userContext.jti,
      userId: userContext.user_id,
      expiresAt,
    });
  }
}

module.exports = new AuthService();
