const { pool } = require('../../config/database');

class ReportsRepository {
  async createReport({ pelaporId, targetTipe, targetId, alasan, keterangan }) {
    const query = `
      INSERT INTO reports (
        pelapor_id,
        target_tipe,
        target_id,
        alasan,
        keterangan,
        status_penanganan,
        dibuat_pada
      ) VALUES ($1, $2, $3, $4, $5, 'Baru', NOW())
      RETURNING *;
    `;
    const values = [pelaporId, targetTipe, targetId, alasan, keterangan];
    const { rows } = await pool.query(query, values);
    return rows[0];
  }

  async findById(reportId) {
    const query = `
      SELECT r.*,
             u.nama AS pelapor_nama,
             u.email AS pelapor_email,
             admin.nama AS admin_nama
      FROM reports r
      LEFT JOIN users u ON r.pelapor_id = u.user_id
      LEFT JOIN users admin ON r.ditangani_oleh = admin.user_id
      WHERE r.report_id = $1;
    `;
    const { rows } = await pool.query(query, [reportId]);
    return rows[0] || null;
  }

  async listByUser(userId) {
    const query = `
      SELECT r.*,
             u.nama AS pelapor_nama
      FROM reports r
      JOIN users u ON r.pelapor_id = u.user_id
      WHERE r.pelapor_id = $1
      ORDER BY r.dibuat_pada DESC;
    `;
    const { rows } = await pool.query(query, [userId]);
    return rows;
  }

  async listAll({ status, limit = 50, offset = 0 } = {}) {
    let query = `
      SELECT r.*,
             u.nama AS pelapor_nama,
             u.email AS pelapor_email
      FROM reports r
      JOIN users u ON r.pelapor_id = u.user_id
    `;
    const params = [];
    if (status) {
      params.push(status);
      query += ` WHERE r.status_penanganan = $${params.length}`;
    }
    query += ` ORDER BY r.dibuat_pada DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2};`;
    params.push(limit, offset);

    const { rows } = await pool.query(query, params);
    return rows;
  }

  async updateResolution(reportId, { statusPenanganan, keputusan, ditanganiOleh }) {
    const query = `
      UPDATE reports
      SET status_penanganan = $1,
          keputusan = COALESCE($2, keputusan),
          ditangani_oleh = $3,
          diselesaikan_pada = CASE WHEN $1 = 'Selesai' THEN NOW() ELSE diselesaikan_pada END
      WHERE report_id = $4
      RETURNING *;
    `;
    const values = [statusPenanganan, keputusan || null, ditanganiOleh, reportId];
    const { rows } = await pool.query(query, values);
    return rows[0] || null;
  }
}

module.exports = new ReportsRepository();
