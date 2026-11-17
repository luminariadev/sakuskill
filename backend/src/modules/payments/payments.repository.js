const db = require('../../config/database');

const MVP_DISCLAIMER = {
  is_simulasi_mvp: true,
  bukan_uang_sungguhan: true,
  bukan_escrow_nyata: true,
  midtrans_ditunda: true,
  keterangan: 'Simulasi pembayaran internal khusus MVP SakuSkill. Tidak melibatkan uang sungguhan, bukan rekening bersama (escrow) perbankan nyata, dan integrasi Midtrans ditunda pasca-MVP.',
};

class PaymentsRepository {
  async findOrderById(orderId) {
    const sql = `
      SELECT
        o.order_id, o.listing_id, o.pelanggan_id, o.penyedia_id,
        o.snapshot_judul, o.harga_kesepakatan, o.status_pesanan, o.status_kode,
        up.nama AS nama_pelanggan, uj.nama AS nama_penyedia
      FROM orders o
      JOIN users up ON up.user_id = o.pelanggan_id
      JOIN users uj ON uj.user_id = o.penyedia_id
      WHERE o.order_id = $1 LIMIT 1;
    `;
    const { rows } = await db.query(sql, [orderId]);
    return rows[0] || null;
  }

  async findByOrderId(orderId) {
    const sql = `
      SELECT
        p.*,
        o.snapshot_judul AS judul_order,
        o.status_kode AS order_status_kode,
        o.status_pesanan AS order_status_label,
        up.nama AS nama_pelanggan,
        uj.nama AS nama_penyedia
      FROM payments p
      JOIN orders o ON o.order_id = p.order_id
      JOIN users up ON up.user_id = p.pelanggan_id
      JOIN users uj ON uj.user_id = p.penyedia_id
      WHERE p.order_id = $1 LIMIT 1;
    `;
    const { rows } = await db.query(sql, [orderId]);
    return rows[0] ? this.formatPayment(rows[0]) : null;
  }

  formatPayment(row) {
    return {
      payment_id: row.payment_id,
      order_id: row.order_id,
      pelanggan_id: row.pelanggan_id,
      penyedia_id: row.penyedia_id,
      nama_pelanggan: row.nama_pelanggan,
      nama_penyedia: row.nama_penyedia,
      judul_order: row.judul_order,
      metode_simulasi: row.metode_simulasi,
      nominal: row.nominal,
      mata_uang: row.mata_uang,
      status_kode: row.status_kode,
      status_pembayaran: row.status_pembayaran,
      referensi_simulasi: row.referensi_simulasi,
      catatan_simulasi: row.catatan_simulasi,
      jumlah_percobaan: row.jumlah_percobaan,
      disimulasikan_pada: row.disimulasikan_pada,
      dibuat_pada: row.dibuat_pada,
      diubah_pada: row.diubah_pada,
      relasi_order: {
        order_id: row.order_id,
        order_status_kode: row.order_status_kode,
        order_status_label: row.order_status_label,
        boleh_lanjut_in_progress: row.status_kode === 'success',
      },
      disclaimer_mvp: MVP_DISCLAIMER,
    };
  }

  async createOrResetPendingPayment({
    orderId,
    pelangganId,
    penyediaId,
    metodeSimulasi,
    nominal,
    referensiSimulasi,
    catatanSimulasi,
  }) {
    const sql = `
      INSERT INTO payments (
        order_id, pelanggan_id, penyedia_id, metode_simulasi, nominal,
        status_kode, status_pembayaran, referensi_simulasi, catatan_simulasi,
        jumlah_percobaan, is_simulasi_mvp, disimulasikan_pada, dibuat_pada, diubah_pada
      )
      VALUES (
        $1, $2, $3, $4, $5, 'pending', 'Menunggu', $6, $7, 1, TRUE, NULL, NOW(), NOW()
      )
      ON CONFLICT (order_id)
      DO UPDATE SET
        metode_simulasi = EXCLUDED.metode_simulasi,
        nominal = EXCLUDED.nominal,
        status_kode = 'pending',
        status_pembayaran = 'Menunggu',
        referensi_simulasi = EXCLUDED.referensi_simulasi,
        catatan_simulasi = EXCLUDED.catatan_simulasi,
        jumlah_percobaan = payments.jumlah_percobaan + 1,
        disimulasikan_pada = NULL,
        diubah_pada = NOW()
      RETURNING order_id;
    `;
    await db.query(sql, [
      orderId,
      pelangganId,
      penyediaId,
      metodeSimulasi,
      nominal,
      referensiSimulasi,
      catatanSimulasi || 'Sesi simulasi pembayaran MVP dibuat (status awal: pending).',
    ]);
    return this.findByOrderId(orderId);
  }

  async updateSimulationStatus(orderId, { statusKode, statusPembayaran, catatanSimulasi }) {
    const sql = `
      UPDATE payments
      SET status_kode = $1,
          status_pembayaran = $2,
          catatan_simulasi = COALESCE($3, catatan_simulasi),
          disimulasikan_pada = NOW(),
          diubah_pada = NOW()
      WHERE order_id = $4;
    `;
    await db.query(sql, [statusKode, statusPembayaran, catatanSimulasi || null, orderId]);
    return this.findByOrderId(orderId);
  }

  async listByUser(userId) {
    const sql = `
      SELECT
        p.*,
        o.snapshot_judul AS judul_order,
        o.status_kode AS order_status_kode,
        o.status_pesanan AS order_status_label,
        up.nama AS nama_pelanggan,
        uj.nama AS nama_penyedia
      FROM payments p
      JOIN orders o ON o.order_id = p.order_id
      JOIN users up ON up.user_id = p.pelanggan_id
      JOIN users uj ON uj.user_id = p.penyedia_id
      WHERE p.pelanggan_id = $1 OR p.penyedia_id = $1
      ORDER BY p.dibuat_pada DESC;
    `;
    const { rows } = await db.query(sql, [userId]);
    return rows.map((r) => this.formatPayment(r));
  }

  async writeAuditLog({ aktorId, aksi, objekId, statusSebelum, statusSesudah }) {
    await db.query(
      `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
       VALUES ($1, $2, 'PaymentsSimulationMVP', $3, $4, $5)`,
      [aktorId || null, aksi, objekId, statusSebelum, statusSesudah]
    );
  }
}

module.exports = new PaymentsRepository();