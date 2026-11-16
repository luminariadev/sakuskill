const db = require('../../config/database');

class PaymentsRepository {
  async findOrderWithCustomer(orderId) {
    const sql = `
      SELECT
        o.order_id, o.listing_id, o.pelanggan_id, o.penyedia_id,
        o.snapshot_judul, o.harga_kesepakatan, o.status_pesanan, o.status_kode,
        u.nama AS nama_pelanggan, u.email AS email_pelanggan
      FROM orders o
      JOIN users u ON u.user_id = o.pelanggan_id
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
        o.status_kode AS status_order_kode,
        o.status_pesanan AS status_order_label,
        up.nama AS nama_pelanggan,
        uj.nama AS nama_penyedia
      FROM payments p
      JOIN orders o ON o.order_id = p.order_id
      JOIN users up ON up.user_id = p.pelanggan_id
      JOIN users uj ON uj.user_id = p.penyedia_id
      WHERE p.order_id = $1 LIMIT 1;
    `;
    const { rows } = await db.query(sql, [orderId]);
    return rows[0] ? this.formatPaymentRow(rows[0]) : null;
  }

  async findByGatewayRefOrOrderId(refOrOrderId) {
    const sql = `
      SELECT p.*
      FROM payments p
      WHERE p.referensi_gateway = $1 OR p.order_id::text = $1
      LIMIT 1;
    `;
    const { rows } = await db.query(sql, [String(refOrOrderId)]);
    if (rows.length === 0) return null;
    return this.findByOrderId(rows[0].order_id);
  }

  formatPaymentRow(row) {
    return {
      ...row,
      ringkasan_escrow: {
        status_pembayaran: row.status_pembayaran,
        status_pembayaran_kode: row.status_pembayaran_kode,
        status_escrow: row.status_escrow,
        status_escrow_kode: row.status_escrow_kode,
        dana_aman_di_escrow: row.status_escrow_kode === 'held',
        dana_dilepas_ke_penyedia: row.status_escrow_kode === 'released',
        dana_dikembalikan_ke_pelanggan: row.status_escrow_kode === 'refunded',
      },
      instruksi_gateway: {
        provider: row.gateway_provider,
        referensi_gateway: row.referensi_gateway,
        metode_pembayaran: row.metode_pembayaran,
        snap_token: row.snap_token,
        payment_url: row.payment_url,
        qr_code_url: row.qr_code_url,
        va_number: row.va_number,
        estimasi_usd: row.nominal_usd_estimasi,
      },
    };
  }

  async upsertCheckoutPayment({
    orderId,
    pelangganId,
    penyediaId,
    metodePembayaran,
    nominal,
    gatewayProvider,
    referensiGateway,
    snapToken,
    paymentUrl,
    qrCodeUrl,
    vaNumber,
    kursUsdReferensi,
    nominalUsdEstimasi,
    rawGatewayResponse,
  }) {
    const sql = `
      INSERT INTO payments (
        order_id, pelanggan_id, penyedia_id, metode_pembayaran, nominal,
        status_pembayaran, status_pembayaran_kode,
        status_escrow, status_escrow_kode,
        gateway_provider, referensi_gateway, snap_token, payment_url, qr_code_url, va_number,
        kurs_usd_referensi, nominal_usd_estimasi, raw_gateway_response,
        kedaluwarsa_pada, dibuat_pada, diubah_pada
      )
      VALUES (
        $1, $2, $3, $4, $5, 'Menunggu', 'pending', 'Belum Aktif', 'none',
        $6, $7, $8, $9, $10, $11, $12, $13, $14::jsonb, NOW() + INTERVAL '24 hours', NOW(), NOW()
      )
      ON CONFLICT (order_id)
      DO UPDATE SET
        metode_pembayaran = EXCLUDED.metode_pembayaran,
        nominal = EXCLUDED.nominal,
        status_pembayaran = 'Menunggu',
        status_pembayaran_kode = 'pending',
        status_escrow = 'Belum Aktif',
        status_escrow_kode = 'none',
        gateway_provider = EXCLUDED.gateway_provider,
        referensi_gateway = EXCLUDED.referensi_gateway,
        snap_token = EXCLUDED.snap_token,
        payment_url = EXCLUDED.payment_url,
        qr_code_url = EXCLUDED.qr_code_url,
        va_number = EXCLUDED.va_number,
        kurs_usd_referensi = EXCLUDED.kurs_usd_referensi,
        nominal_usd_estimasi = EXCLUDED.nominal_usd_estimasi,
        raw_gateway_response = EXCLUDED.raw_gateway_response,
        kedaluwarsa_pada = NOW() + INTERVAL '24 hours',
        diubah_pada = NOW()
      RETURNING order_id;
    `;
    await db.query(sql, [
      orderId,
      pelangganId,
      penyediaId,
      metodePembayaran,
      nominal,
      gatewayProvider,
      referensiGateway,
      snapToken,
      paymentUrl,
      qrCodeUrl,
      vaNumber,
      kursUsdReferensi,
      nominalUsdEstimasi,
      JSON.stringify(rawGatewayResponse || {}),
    ]);
    return this.findByOrderId(orderId);
  }

  async updatePaymentAndEscrowState(orderId, {
    statusPembayaran,
    statusPembayaranKode,
    statusEscrow,
    statusEscrowKode,
    catatanEscrow,
    markPaidNow,
    markReleasedNow,
    markRefundedNow,
  }) {
    const sql = `
      UPDATE payments
      SET status_pembayaran = $1,
          status_pembayaran_kode = $2,
          status_escrow = $3,
          status_escrow_kode = $4,
          catatan_escrow = COALESCE($5, catatan_escrow),
          dibayar_pada = CASE WHEN $6::boolean THEN COALESCE(dibayar_pada, NOW()) ELSE dibayar_pada END,
          escrow_dilepas_pada = CASE WHEN $7::boolean THEN NOW() ELSE escrow_dilepas_pada END,
          escrow_dikembalikan_pada = CASE WHEN $8::boolean THEN NOW() ELSE escrow_dikembalikan_pada END,
          diubah_pada = NOW()
      WHERE order_id = $9;
    `;
    await db.query(sql, [
      statusPembayaran,
      statusPembayaranKode,
      statusEscrow,
      statusEscrowKode,
      catatanEscrow || null,
      Boolean(markPaidNow),
      Boolean(markReleasedNow),
      Boolean(markRefundedNow),
      orderId,
    ]);
    return this.findByOrderId(orderId);
  }

  async listUserPayments(userId) {
    const sql = `
      SELECT
        p.*,
        o.snapshot_judul AS judul_order,
        o.status_kode AS status_order_kode,
        o.status_pesanan AS status_order_label,
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
    return rows.map((r) => this.formatPaymentRow(r));
  }

  async getEscrowSummary(userId) {
    const sql = `
      SELECT
        COALESCE(SUM(CASE WHEN status_escrow_kode = 'held' AND (pelanggan_id = $1 OR penyedia_id = $1) THEN nominal ELSE 0 END), 0)::numeric(12,2) AS total_dana_ditahan_escrow,
        COALESCE(SUM(CASE WHEN status_escrow_kode = 'released' AND penyedia_id = $1 THEN nominal ELSE 0 END), 0)::numeric(12,2) AS total_pendapatan_dilepas_penyedia,
        COALESCE(SUM(CASE WHEN status_escrow_kode = 'released' AND pelanggan_id = $1 THEN nominal ELSE 0 END), 0)::numeric(12,2) AS total_pembayaran_selesai_pelanggan,
        COALESCE(SUM(CASE WHEN status_escrow_kode = 'refunded' AND pelanggan_id = $1 THEN nominal ELSE 0 END), 0)::numeric(12,2) AS total_dana_dikembalikan_refund,
        COUNT(*)::int AS total_transaksi_pembayaran
      FROM payments
      WHERE pelanggan_id = $1 OR penyedia_id = $1;
    `;
    const { rows } = await db.query(sql, [userId]);
    return rows[0];
  }

  async writeAuditLog({ aktorId, aksi, objekId, statusSebelum, statusSesudah }) {
    await db.query(
      `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
       VALUES ($1, $2, 'PaymentsEscrow', $3, $4, $5)`,
      [aktorId || null, aksi, objekId, statusSebelum, statusSesudah]
    );
  }
}

module.exports = new PaymentsRepository();