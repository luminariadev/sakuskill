const db = require('../../config/database');

class AuthRepository {
  async findByEmail(email) {
    const sql = `
      SELECT user_id, nama, email, kata_sandi_hash, peran, status_verifikasi, deskripsi_profil, foto_profil, dibuat_pada
      FROM users
      WHERE LOWER(email) = LOWER($1)
      LIMIT 1;
    `;
    const { rows } = await db.query(sql, [email]);
    return rows[0] || null;
  }

  async createUser({ nama, email, kataSandiHash, peran, deskripsiProfil }) {
    const sql = `
      INSERT INTO users (nama, email, kata_sandi_hash, peran, deskripsi_profil)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING user_id, nama, email, peran, status_verifikasi, deskripsi_profil, foto_profil, dibuat_pada;
    `;
    const { rows } = await db.query(sql, [
      nama,
      email,
      kataSandiHash,
      peran || 'Penyedia Jasa',
      deskripsiProfil || null,
    ]);
    return rows[0];
  }

  async revokeToken({ jti, userId, expiresAt }) {
    const sql = `
      INSERT INTO revoked_tokens (jti, user_id, expires_at)
      VALUES ($1, $2, $3)
      ON CONFLICT (jti) DO NOTHING;
    `;
    await db.query(sql, [jti, userId, expiresAt]);
  }

  async writeAuditLog({ aktorId, aksi, objekTipe, objekId, statusSebelum, statusSesudah }) {
    const sql = `
      INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
      VALUES ($1, $2, $3, $4, $5, $6);
    `;
    await db.query(sql, [aktorId, aksi, objekTipe, objekId, statusSebelum, statusSesudah]);
  }
}

module.exports = new AuthRepository();
