const db = require('../../config/database');

class OrdersRepository {
  async findGigForOrder(listingId) {
    const sql = `
      SELECT listing_id, penyedia_id, judul, deskripsi, harga, tipe_penawaran, status
      FROM service_listings
      WHERE listing_id = $1 LIMIT 1;
    `;
    const { rows } = await db.query(sql, [listingId]);
    return rows[0] || null;
  }

  async createOrder({
    listingId,
    pelangganId,
    penyediaId,
    snapshotJudul,
    snapshotHarga,
    snapshotKetentuan,
    ruangLingkup,
    hargaKesepakatan,
    tenggatPekerjaan,
  }) {
    const sql = `
      INSERT INTO orders (
        listing_id, pelanggan_id, penyedia_id,
        snapshot_judul, snapshot_harga, snapshot_ketentuan,
        catatan_kebutuhan, ruang_lingkup, harga_kesepakatan, tenggat_pekerjaan,
        status_pesanan, status_kode
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING order_id;
    `;
    const { rows } = await db.query(sql, [
      listingId,
      pelangganId,
      penyediaId,
      snapshotJudul,
      snapshotHarga,
      snapshotKetentuan,
      ruangLingkup,
      ruangLingkup,
      hargaKesepakatan,
      tenggatPekerjaan,
      'Diajukan',
      'requested',
    ]);
    return this.findById(rows[0].order_id);
  }

  async findById(orderId) {
    const sql = `
      SELECT
        o.order_id,
        o.listing_id,
        o.pelanggan_id,
        o.penyedia_id,
        o.snapshot_judul,
        o.snapshot_harga,
        o.snapshot_ketentuan,
        o.ruang_lingkup,
        o.catatan_kebutuhan,
        o.harga_kesepakatan,
        o.tenggat_pekerjaan,
        o.status_pesanan,
        o.status_kode,
        o.alasan_pembatalan,
        o.dikonfirmasi_selesai_pada,
        o.dibuat_pada,
        o.diubah_pada,
        up.nama AS nama_pelanggan,
        uj.nama AS nama_penyedia
      FROM orders o
      JOIN users up ON up.user_id = o.pelanggan_id
      JOIN users uj ON uj.user_id = o.penyedia_id
      WHERE o.order_id = $1 LIMIT 1;
    `;
    const { rows } = await db.query(sql, [orderId]);
    if (rows.length === 0) return null;

    const order = rows[0];
    const { rows: proposals } = await db.query(
      `SELECT proposal_id, pengaju_id, harga_tawaran, deskripsi_ruang_lingkup, tenggat_usulan, status_proposal, dibuat_pada
       FROM order_proposals WHERE order_id = $1 ORDER BY dibuat_pada ASC`,
      [orderId]
    );
    const { rows: reviews } = await db.query(
      `SELECT review_id, pemberi_id, penerima_id, rating, rating_kualitas, rating_ketepatan_waktu, komentar, dibuat_pada
       FROM reviews WHERE order_id = $1`,
      [orderId]
    );

    return {
      ...order,
      snapshot_gig: {
        judul: order.snapshot_judul,
        harga_awal: order.snapshot_harga,
        ketentuan: order.snapshot_ketentuan,
      },
      kesepakatan: {
        scope: order.ruang_lingkup || order.catatan_kebutuhan,
        harga_final: order.harga_kesepakatan,
        deadline: order.tenggat_pekerjaan,
      },
      proposals,
      reviews,
    };
  }

  async findByUser(userId, { role, status } = {}) {
    const params = [userId];
    const where = ['(o.pelanggan_id = $1 OR o.penyedia_id = $1)'];
    let idx = 2;

    if (role === 'pelanggan') {
      where.push('o.pelanggan_id = $1');
    } else if (role === 'penyedia') {
      where.push('o.penyedia_id = $1');
    }

    if (status) {
      params.push(status);
      const p = '$' + idx++;
      where.push('(LOWER(o.status_kode) = LOWER(' + p + ') OR LOWER(o.status_pesanan) = LOWER(' + p + '))');
    }

    const sql = [
      'SELECT',
      '  o.order_id, o.listing_id, o.pelanggan_id, o.penyedia_id,',
      '  o.snapshot_judul, o.snapshot_harga, o.ruang_lingkup,',
      '  o.harga_kesepakatan, o.tenggat_pekerjaan,',
      '  o.status_pesanan, o.status_kode, o.dibuat_pada, o.diubah_pada,',
      '  up.nama AS nama_pelanggan, uj.nama AS nama_penyedia',
      'FROM orders o',
      'JOIN users up ON up.user_id = o.pelanggan_id',
      'JOIN users uj ON uj.user_id = o.penyedia_id',
      'WHERE ' + where.join(' AND '),
      'ORDER BY o.dibuat_pada DESC;'
    ].join('\n');

    const { rows } = await db.query(sql, params);
    return rows;
  }

  async addProposal({ orderId, pengajuId, hargaTawaran, deskripsiRuangLingkup, tenggatUsulan }) {
    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `INSERT INTO order_proposals (order_id, pengaju_id, harga_tawaran, deskripsi_ruang_lingkup, tenggat_usulan, status_proposal)
         VALUES ($1, $2, $3, $4, $5, 'Menunggu')`,
        [orderId, pengajuId, hargaTawaran, deskripsiRuangLingkup, tenggatUsulan || null]
      );
      await client.query(
        `UPDATE orders
         SET ruang_lingkup = $1,
             catatan_kebutuhan = $1,
             harga_kesepakatan = $2,
             tenggat_pekerjaan = COALESCE($3, tenggat_pekerjaan),
             status_pesanan = 'Dalam Negosiasi',
             status_kode = 'negotiating',
             diubah_pada = NOW()
         WHERE order_id = $4`,
        [deskripsiRuangLingkup, hargaTawaran, tenggatUsulan || null, orderId]
      );
      await client.query('COMMIT');
      return this.findById(orderId);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async updateOrderState(orderId, {
    statusPesanan,
    statusKode,
    ruangLingkup,
    hargaKesepakatan,
    tenggatPekerjaan,
    alasanPembatalan,
    markCompletedNow,
  }) {
    const sql = `
      UPDATE orders
      SET status_pesanan = $1,
          status_kode = $2,
          ruang_lingkup = COALESCE($3, ruang_lingkup),
          catatan_kebutuhan = COALESCE($3, catatan_kebutuhan),
          harga_kesepakatan = COALESCE($4, harga_kesepakatan),
          tenggat_pekerjaan = COALESCE($5, tenggat_pekerjaan),
          alasan_pembatalan = COALESCE($6, alasan_pembatalan),
          dikonfirmasi_selesai_pada = CASE WHEN $7::boolean THEN NOW() ELSE dikonfirmasi_selesai_pada END,
          diubah_pada = NOW()
      WHERE order_id = $8;
    `;
    await db.query(sql, [
      statusPesanan,
      statusKode,
      ruangLingkup ?? null,
      hargaKesepakatan ?? null,
      tenggatPekerjaan ?? null,
      alasanPembatalan ?? null,
      Boolean(markCompletedNow),
      orderId,
    ]);

    if (statusKode === 'accepted') {
      await db.query(
        `UPDATE order_proposals SET status_proposal = 'Disetujui' WHERE order_id = $1 AND status_proposal = 'Menunggu'`,
        [orderId]
      );
    }
    return this.findById(orderId);
  }

  async findReviewByOrderAndAuthor(orderId, pemberiId) {
    const { rows } = await db.query(
      `SELECT review_id FROM reviews WHERE order_id = $1 AND pemberi_id = $2 LIMIT 1`,
      [orderId, pemberiId]
    );
    return rows[0] || null;
  }

  async createReview({ orderId, pemberiId, penerimaId, rating, ratingKualitas, ratingKetepatanWaktu, komentar }) {
    const sql = `
      INSERT INTO reviews (
        transaksi_tipe, order_id, pemberi_id, penerima_id,
        rating, rating_kualitas, rating_ketepatan_waktu, komentar, status_moderasi
      )
      VALUES ('Order', $1, $2, $3, $4, $5, $6, $7, 'Tampil')
      RETURNING *;
    `;
    const { rows } = await db.query(sql, [
      orderId,
      pemberiId,
      penerimaId,
      rating,
      ratingKualitas || rating,
      ratingKetepatanWaktu || rating,
      komentar || null,
    ]);
    return rows[0];
  }

  async writeAuditLog({ aktorId, aksi, objekId, statusSebelum, statusSesudah }) {
    await db.query(
      `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
       VALUES ($1, $2, 'Orders', $3, $4, $5)`,
      [aktorId, aksi, objekId, statusSebelum, statusSesudah]
    );
  }

  async findMessagesByOrderId(orderId) {
    const sql = `
      SELECT
        m.message_id,
        m.order_id,
        m.sender_id,
        u.nama AS sender_nama,
        m.isi_pesan,
        m.dibuat_pada
      FROM order_messages m
      JOIN users u ON u.user_id = m.sender_id
      WHERE m.order_id = $1
      ORDER BY m.dibuat_pada ASC;
    `;
    const { rows } = await db.query(sql, [orderId]);
    return rows;
  }

  async createMessage({ orderId, senderId, isiPesan }) {
    const insertSql = `
      INSERT INTO order_messages (order_id, sender_id, isi_pesan)
      VALUES ($1, $2, $3)
      RETURNING message_id;
    `;
    const { rows } = await db.query(insertSql, [orderId, senderId, isiPesan]);

    const detailSql = `
      SELECT
        m.message_id,
        m.order_id,
        m.sender_id,
        u.nama AS sender_nama,
        m.isi_pesan,
        m.dibuat_pada
      FROM order_messages m
      JOIN users u ON u.user_id = m.sender_id
      WHERE m.message_id = $1
      LIMIT 1;
    `;
    const detail = await db.query(detailSql, [rows[0].message_id]);
    return detail.rows[0];
  }
}

module.exports = new OrdersRepository();