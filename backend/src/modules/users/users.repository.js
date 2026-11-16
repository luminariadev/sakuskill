const db = require('../../config/database');

class UsersRepository {
  async findFullProfileById(userId) {
    const userSql = `
      SELECT
        u.user_id,
        u.nama,
        u.email,
        u.peran,
        u.status_verifikasi,
        u.deskripsi_profil,
        u.dibuat_pada,
        COALESCE(ROUND(AVG(r.rating)::numeric, 2), 0.00) AS rata_rata_rating,
        COUNT(r.review_id)::int AS jumlah_ulasan
      FROM users u
      LEFT JOIN reviews r
        ON r.penerima_id = u.user_id AND r.status_moderasi = 'Tampil'
      WHERE u.user_id = $1
      GROUP BY u.user_id;
    `;
    const { rows: userRows } = await db.query(userSql, [userId]);
    if (userRows.length === 0) return null;

    const skillsSql = `
      SELECT s.skill_id, s.nama_keterampilan, s.kategori
      FROM provider_skills ps
      JOIN skills s ON s.skill_id = ps.skill_id
      WHERE ps.user_id = $1
      ORDER BY s.kategori ASC, s.nama_keterampilan ASC;
    `;
    const { rows: skills } = await db.query(skillsSql, [userId]);

    const portfolioSql = `
      SELECT portfolio_id, judul, deskripsi, berkas_ref, dibuat_pada
      FROM portfolio_items
      WHERE penyedia_id = $1
      ORDER BY dibuat_pada DESC;
    `;
    const { rows: portfolio } = await db.query(portfolioSql, [userId]);

    return {
      ...userRows[0],
      rata_rata_rating: parseFloat(userRows[0].rata_rata_rating),
      keterampilan: skills,
      portofolio: portfolio,
    };
  }

  async updateProfile(userId, { nama, deskripsiProfil, skillIds }) {
    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      if (nama !== undefined || deskripsiProfil !== undefined) {
        const fields = [];
        const values = [];
        let idx = 1;

        if (nama !== undefined) {
          fields.push(`nama = $${idx++}`);
          values.push(nama);
        }
        if (deskripsiProfil !== undefined) {
          fields.push(`deskripsi_profil = $${idx++}`);
          values.push(deskripsiProfil);
        }
        values.push(userId);

        await client.query(
          `UPDATE users SET ${fields.join(', ')} WHERE user_id = $${idx}`,
          values
        );
      }

      if (Array.isArray(skillIds)) {
        if (skillIds.length > 0) {
          const { rows: validSkills } = await client.query(
            'SELECT skill_id FROM skills WHERE skill_id = ANY($1::int[])',
            [skillIds]
          );
          if (validSkills.length !== new Set(skillIds).size) {
            const err = new Error('Terdapat ID keterampilan (skill_id) yang tidak ditemukan.');
            err.code = 'INVALID_SKILL_ID';
            throw err;
          }
        }

        await client.query('DELETE FROM provider_skills WHERE user_id = $1', [userId]);
        for (const skillId of new Set(skillIds)) {
          await client.query(
            'INSERT INTO provider_skills (user_id, skill_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, skillId]
          );
        }
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async updateVerificationStatus({ targetUserId, statusVerifikasi, adminId }) {
    const { rows: existing } = await db.query(
      'SELECT user_id, status_verifikasi FROM users WHERE user_id = $1 LIMIT 1',
      [targetUserId]
    );
    if (existing.length === 0) return null;

    const statusSebelum = existing[0].status_verifikasi;
    const { rows } = await db.query(
      `UPDATE users SET status_verifikasi = $1 WHERE user_id = $2
       RETURNING user_id, nama, email, peran, status_verifikasi, dibuat_pada`,
      [statusVerifikasi, targetUserId]
    );

    await db.query(
      `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
       VALUES ($1, 'VERIFY_USER_ACCOUNT', 'Users', $2, $3, $4)`,
      [adminId, targetUserId, statusSebelum, statusVerifikasi]
    );

    return rows[0];
  }
}

module.exports = new UsersRepository();

