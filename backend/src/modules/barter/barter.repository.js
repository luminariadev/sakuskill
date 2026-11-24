const db = require('../../config/database');

class BarterRepository {
  async findGigById(listingId) {
    const { rows } = await db.query(
      `SELECT listing_id, penyedia_id, judul, deskripsi, tipe_penawaran, status
       FROM service_listings WHERE listing_id = $1 LIMIT 1`,
      [listingId]
    );
    return rows[0] || null;
  }

  async createBarter({
    listingId,
    listingPengajuId,
    pengajuId,
    penerimaId,
    deskripsiJasaPengaju,
    deskripsiJasaPenerima,
    tenggatPekerjaan,
  }) {
    const sql = `
      INSERT INTO barter_agreements (
        listing_id, listing_pengaju_id, pengaju_id, penerima_id,
        deskripsi_jasa_pengaju, deskripsi_jasa_penerima, tenggat_pekerjaan,
        setuju_pengaju, setuju_penerima,
        konfirmasi_selesai_pengaju, konfirmasi_selesai_penerima,
        status, status_kode
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE, FALSE, FALSE, FALSE, 'Diajukan', 'requested')
      RETURNING barter_id;
    `;
    const { rows } = await db.query(sql, [
      listingId,
      listingPengajuId || null,
      pengajuId,
      penerimaId,
      deskripsiJasaPengaju,
      deskripsiJasaPenerima,
      tenggatPekerjaan,
    ]);
    return this.findById(rows[0].barter_id);
  }

  async findById(barterId) {
    const sql = `
      SELECT
        b.*,
        u1.nama AS nama_pengaju,
        u2.nama AS nama_penerima,
        sl1.judul AS judul_gig_penerima,
        sl2.judul AS judul_gig_pengaju
      FROM barter_agreements b
      JOIN users u1 ON u1.user_id = b.pengaju_id
      JOIN users u2 ON u2.user_id = b.penerima_id
      LEFT JOIN service_listings sl1 ON sl1.listing_id = b.listing_id
      LEFT JOIN service_listings sl2 ON sl2.listing_id = b.listing_pengaju_id
      WHERE b.barter_id = $1 LIMIT 1;
    `;
    const { rows } = await db.query(sql, [barterId]);
    if (rows.length === 0) return null;

    const barter = rows[0];
    const { rows: confirmations } = await db.query(
      `SELECT confirmation_id, user_id, peran_dalam_barter, catatan, status_konfirmasi, dikonfirmasi_pada
       FROM barter_confirmations WHERE barter_id = $1 ORDER BY dikonfirmasi_pada ASC`,
      [barterId]
    );

    return {
      ...barter,
      persetujuan_kedua_pihak: {
        setuju_pengaju: barter.setuju_pengaju,
        setuju_penerima: barter.setuju_penerima,
        siap_in_progress: Boolean(barter.setuju_pengaju && barter.setuju_penerima),
      },
      konfirmasi_penyelesaian: {
        pengaju_konfirmasi: barter.konfirmasi_selesai_pengaju,
        penerima_konfirmasi: barter.konfirmasi_selesai_penerima,
        waktu_konfirmasi_pengaju: barter.waktu_konfirmasi_pengaju,
        waktu_konfirmasi_penerima: barter.waktu_konfirmasi_penerima,
        keduanya_selesai: Boolean(barter.konfirmasi_selesai_pengaju && barter.konfirmasi_selesai_penerima),
        riwayat_konfirmasi: confirmations,
      },
    };
  }

  async findByUser(userId) {
    const sql = `
      SELECT
        b.barter_id, b.listing_id, b.listing_pengaju_id, b.pengaju_id, b.penerima_id,
        b.deskripsi_jasa_pengaju, b.deskripsi_jasa_penerima, b.tenggat_pekerjaan,
        b.setuju_pengaju, b.setuju_penerima,
        b.konfirmasi_selesai_pengaju, b.konfirmasi_selesai_penerima,
        b.status, b.status_kode, b.dibuat_pada, b.diubah_pada,
        u1.nama AS nama_pengaju, u2.nama AS nama_penerima
      FROM barter_agreements b
      JOIN users u1 ON u1.user_id = b.pengaju_id
      JOIN users u2 ON u2.user_id = b.penerima_id
      WHERE b.pengaju_id = $1 OR b.penerima_id = $1
      ORDER BY b.dibuat_pada DESC;
    `;
    const { rows } = await db.query(sql, [userId]);
    return rows;
  }

  async updateTerms(barterId, { deskripsiJasaPengaju, deskripsiJasaPenerima, tenggatPekerjaan, setujuPengaju, setujuPenerima }) {
    const sql = `
      UPDATE barter_agreements
      SET deskripsi_jasa_pengaju = COALESCE($1, deskripsi_jasa_pengaju),
          deskripsi_jasa_penerima = COALESCE($2, deskripsi_jasa_penerima),
          tenggat_pekerjaan = COALESCE($3, tenggat_pekerjaan),
          setuju_pengaju = $4,
          setuju_penerima = $5,
          status = 'Dalam Negosiasi',
          status_kode = 'negotiating',
          diubah_pada = NOW()
      WHERE barter_id = $6;
    `;
    await db.query(sql, [
      deskripsiJasaPengaju ?? null,
      deskripsiJasaPenerima ?? null,
      tenggatPekerjaan ?? null,
      setujuPengaju,
      setujuPenerima,
      barterId,
    ]);
    return this.findById(barterId);
  }

  async updateBarterState(barterId, {
    status,
    statusKode,
    setujuPengaju,
    setujuPenerima,
    alasanPembatalan,
  }) {
    const sql = `
      UPDATE barter_agreements
      SET status = $1,
          status_kode = $2,
          setuju_pengaju = COALESCE($3, setuju_pengaju),
          setuju_penerima = COALESCE($4, setuju_penerima),
          alasan_pembatalan = COALESCE($5, alasan_pembatalan),
          diubah_pada = NOW()
      WHERE barter_id = $6;
    `;
    await db.query(sql, [
      status,
      statusKode,
      setujuPengaju ?? null,
      setujuPenerima ?? null,
      alasanPembatalan ?? null,
      barterId,
    ]);
    return this.findById(barterId);
  }

  async recordPartyCompletion({ barterId, userId, isInitiator, catatan }) {
    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');
      const peranLabel = isInitiator ? 'Pengaju' : 'Penerima';

      await client.query(
        `INSERT INTO barter_confirmations (barter_id, user_id, peran_dalam_barter, catatan, status_konfirmasi, dikonfirmasi_pada)
         VALUES ($1, $2, $3, $4, TRUE, NOW())
         ON CONFLICT (barter_id, user_id)
         DO UPDATE SET catatan = EXCLUDED.catatan, status_konfirmasi = TRUE, dikonfirmasi_pada = NOW()`,
        [barterId, userId, peranLabel, catatan || null]
      );

      if (isInitiator) {
        await client.query(
          `UPDATE barter_agreements
           SET konfirmasi_selesai_pengaju = TRUE, waktu_konfirmasi_pengaju = NOW(), diubah_pada = NOW()
           WHERE barter_id = $1`,
          [barterId]
        );
      } else {
        await client.query(
          `UPDATE barter_agreements
           SET konfirmasi_selesai_penerima = TRUE, waktu_konfirmasi_penerima = NOW(), diubah_pada = NOW()
           WHERE barter_id = $1`,
          [barterId]
        );
      }

      const { rows } = await client.query(
        `SELECT konfirmasi_selesai_pengaju, konfirmasi_selesai_penerima FROM barter_agreements WHERE barter_id = $1`,
        [barterId]
      );
      const bothConfirmed = Boolean(
        rows[0].konfirmasi_selesai_pengaju && rows[0].konfirmasi_selesai_penerima
      );

      // Kerjaan #9: Jangan tandai selesai (completed) sebelum KEDUANYA konfirmasi!
      const nextStatusKode = bothConfirmed ? 'completed' : 'completion_requested';
      const nextStatusLabel = bothConfirmed ? 'Selesai' : 'Menunggu Konfirmasi';

      await client.query(
        `UPDATE barter_agreements SET status = $1, status_kode = $2, diubah_pada = NOW() WHERE barter_id = $3`,
        [nextStatusLabel, nextStatusKode, barterId]
      );

      await client.query('COMMIT');
      return this.findById(barterId);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async findReviewByBarterAndAuthor(barterId, pemberiId) {
    const { rows } = await db.query(
      `SELECT review_id FROM reviews WHERE barter_id = $1 AND pemberi_id = $2 LIMIT 1`,
      [barterId, pemberiId]
    );
    return rows[0] || null;
  }

  async createBarterReview({ barterId, pemberiId, penerimaId, rating, ratingKualitas, ratingKetepatanWaktu, komentar }) {
    const sql = `
      INSERT INTO reviews (
        transaksi_tipe, barter_id, pemberi_id, penerima_id,
        rating, rating_kualitas, rating_ketepatan_waktu, komentar, status_moderasi
      )
      VALUES ('Barter', $1, $2, $3, $4, $5, $6, $7, 'Tampil')
      RETURNING *;
    `;
    const { rows } = await db.query(sql, [
      barterId,
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
       VALUES ($1, $2, 'BarterAgreements', $3, $4, $5)`,
      [aktorId, aksi, objekId, statusSebelum, statusSesudah]
    );
  }

  async ensureMessagesTable() {
    if (this._messagesTableReady) return;
    await db.query(`
      CREATE TABLE IF NOT EXISTS barter_messages (
        message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        barter_id UUID NOT NULL REFERENCES barter_agreements(barter_id) ON DELETE CASCADE,
        sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
        isi_pesan TEXT NOT NULL,
        dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);
    this._messagesTableReady = true;
  }

  async listMessages(barterId) {
    await this.ensureMessagesTable();
    const { rows } = await db.query(
      `SELECT m.message_id, m.barter_id, m.sender_id, m.isi_pesan, m.dibuat_pada,
              u.nama AS nama_pengirim
       FROM barter_messages m
       JOIN users u ON u.user_id = m.sender_id
       WHERE m.barter_id = $1
       ORDER BY m.dibuat_pada ASC`,
      [barterId]
    );
    return rows;
  }

  async createMessage({ barterId, senderId, isiPesan }) {
    await this.ensureMessagesTable();
    const { rows } = await db.query(
      `INSERT INTO barter_messages (barter_id, sender_id, isi_pesan)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [barterId, senderId, isiPesan]
    );
    return rows[0];
  }
}

module.exports = new BarterRepository();