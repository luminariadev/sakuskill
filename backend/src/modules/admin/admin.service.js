const db = require('../../config/database');
const AppError = require('../../utils/AppError');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const CAMPUS_LABEL = 'UIN Sunan Gunung Djati Bandung (Kampus Cibiru)';
const SAFE_ETHICS_PATTERN = /\b(anti[- ]?joki|bebas[- ]?joki|bukan joki|larangan joki|dilarang joki)\b/i;
const JOKI_PATTERN = /\b(joki|calo|skripsi kilat|buatkan skripsi|tugas kilat|ujian online)\b/i;

function isAcademicViolation(text) {
  const cleaned = String(text || '').replace(new RegExp(SAFE_ETHICS_PATTERN.source, 'gi'), ' ');
  return JOKI_PATTERN.test(cleaned);
}

function isUuid(value) {
  return typeof value === 'string' && UUID_REGEX.test(value.trim());
}

function formatRupiah(nominal) {
  const value = Math.round(Number(nominal) || 0);
  return `Rp ${value.toLocaleString('id-ID')}`;
}

function formatRelativeTime(dateInput) {
  if (!dateInput) return '-';
  const ts = new Date(dateInput).getTime();
  if (Number.isNaN(ts)) return '-';
  const diffSec = Math.max(0, Math.floor((Date.now() - ts) / 1000));
  if (diffSec < 60) return 'Baru saja';
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin} menit lalu`;
  const diffHours = Math.floor(diffMin / 60);
  if (diffHours < 24) return `${diffHours} jam lalu`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays} hari lalu`;
}

function formatDateId(dateInput) {
  if (!dateInput) return '-';
  const date = new Date(dateInput);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

function extractUrls(text) {
  if (!text) return [];
  const matches = String(text).match(/https?:\/\/[^\s)]+/gi) || [];
  return [...new Set(matches)];
}

function shortCode(prefix, uuid) {
  return `${prefix}-${String(uuid || '').slice(0, 8).toUpperCase()}`;
}

function orderStatusTone(statusKode, statusPesanan) {
  const code = String(statusKode || '').toLowerCase();
  const label = String(statusPesanan || '').toLowerCase();
  if (code === 'disputed' || label.includes('sengketa')) return 'danger';
  if (code === 'completed') return 'success';
  if (code === 'cancelled' || code === 'rejected') return 'danger';
  if (code === 'in_progress' || code === 'completion_requested') return 'info';
  return 'warning';
}

function barterStatusTone(statusKode) {
  const code = String(statusKode || '').toLowerCase();
  if (code === 'completed') return 'success';
  if (code === 'cancelled' || code === 'rejected') return 'danger';
  if (code === 'in_progress' || code === 'completion_requested' || code === 'accepted') return 'purple';
  return 'warning';
}

class AdminService {
  async writeAuditLog({ aktorId, aksi, objekTipe, objekId, statusSebelum = null, statusSesudah }) {
    if (!isUuid(objekId)) return;
    await db.query(
      `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [isUuid(aktorId) ? aktorId : null, aksi, objekTipe, objekId, statusSebelum, statusSesudah]
    );
  }

  async getDashboard() {
    const [userRes, orderRes, escrowRes, listingRes, barterRes, reportRes, recentRes, slaOrderRes, slaReportRes] =
      await Promise.all([
        db.query(`
          SELECT
            COUNT(*)::int AS total,
            COUNT(CASE WHEN status_verifikasi = 'Terverifikasi' THEN 1 END)::int AS terverifikasi,
            COUNT(CASE WHEN status_verifikasi = 'Belum Terverifikasi' THEN 1 END)::int AS belum_terverifikasi
          FROM users
        `),
        db.query(`
          SELECT
            COUNT(CASE WHEN status_kode IN ('requested','negotiating','accepted','in_progress','completion_requested') THEN 1 END)::int AS aktif,
            COUNT(CASE WHEN status_kode = 'disputed' OR status_pesanan = 'Dalam Sengketa' THEN 1 END)::int AS sengketa,
            COUNT(CASE WHEN status_kode = 'completed' THEN 1 END)::int AS selesai
          FROM orders
        `),
        db.query(`
          SELECT
            COALESCE(SUM(CASE WHEN p.status_kode = 'success' AND o.status_kode IN ('in_progress','completion_requested','disputed') THEN p.nominal ELSE 0 END), 0)::numeric AS ditahan,
            COALESCE(SUM(CASE WHEN p.status_kode = 'success' AND o.status_kode = 'completed' THEN p.nominal ELSE 0 END), 0)::numeric AS dilepas,
            COUNT(CASE WHEN p.status_kode = 'success' AND o.status_kode IN ('in_progress','completion_requested','disputed') THEN 1 END)::int AS escrow_aktif_count
          FROM payments p
          JOIN orders o ON o.order_id = p.order_id
        `),
        db.query(`
          SELECT
            COUNT(*)::int AS total,
            COUNT(CASE WHEN status = 'Aktif' THEN 1 END)::int AS aktif
          FROM service_listings
        `),
        db.query(`
          SELECT
            COUNT(*)::int AS total,
            COUNT(CASE WHEN status_kode IN ('requested','negotiating','accepted','in_progress','completion_requested') THEN 1 END)::int AS aktif
          FROM barter_agreements
        `),
        db.query(`
          SELECT
            COUNT(CASE WHEN status_penanganan != 'Selesai' THEN 1 END)::int AS terbuka,
            COUNT(CASE WHEN status_penanganan = 'Baru' THEN 1 END)::int AS baru
          FROM reports
        `),
        db.query(`
          SELECT * FROM (
            SELECT
              o.order_id::text AS raw_id,
              'ORD' AS prefix,
              'Pesanan Jasa' AS tipe,
              u1.nama || ' → ' || u2.nama AS entitas,
              o.snapshot_judul || ' (' || COALESCE(NULLIF(o.status_pesanan, ''), o.status_kode) || ')' AS keterangan,
              o.status_pesanan AS status,
              o.status_kode AS status_kode,
              'escrow' AS target_tab,
              o.diubah_pada AS ts
            FROM orders o
            JOIN users u1 ON u1.user_id = o.pelanggan_id
            JOIN users u2 ON u2.user_id = o.penyedia_id
            UNION ALL
            SELECT
              b.barter_id::text AS raw_id,
              'BTR' AS prefix,
              'Smart Barter' AS tipe,
              u1.nama || ' ↔ ' || u2.nama AS entitas,
              LEFT(b.deskripsi_jasa_pengaju, 70) AS keterangan,
              b.status AS status,
              b.status_kode AS status_kode,
              'escrow' AS target_tab,
              b.diubah_pada AS ts
            FROM barter_agreements b
            JOIN users u1 ON u1.user_id = b.pengaju_id
            JOIN users u2 ON u2.user_id = b.penerima_id
            UNION ALL
            SELECT
              r.report_id::text AS raw_id,
              'REP' AS prefix,
              'Laporan & Aduan' AS tipe,
              u.nama AS entitas,
              r.alasan AS keterangan,
              r.status_penanganan::text AS status,
              r.status_penanganan::text AS status_kode,
              'reports' AS target_tab,
              r.dibuat_pada AS ts
            FROM reports r
            JOIN users u ON u.user_id = r.pelapor_id
            UNION ALL
            SELECT
              u.user_id::text AS raw_id,
              'USR' AS prefix,
              'Registrasi Akun' AS tipe,
              u.nama AS entitas,
              u.email || ' (' || u.status_verifikasi::text || ')' AS keterangan,
              u.status_verifikasi::text AS status,
              u.status_verifikasi::text AS status_kode,
              'users' AS target_tab,
              u.dibuat_pada AS ts
            FROM users u
          ) feed
          ORDER BY ts DESC
          LIMIT 12
        `),
        db.query(`
          SELECT
            o.order_id,
            o.snapshot_judul,
            o.harga_kesepakatan,
            o.diubah_pada,
            u1.nama AS pelanggan_nama,
            u2.nama AS penyedia_nama,
            FLOOR(EXTRACT(EPOCH FROM (NOW() - o.diubah_pada)) / 3600)::int AS hours_elapsed
          FROM orders o
          JOIN users u1 ON u1.user_id = o.pelanggan_id
          JOIN users u2 ON u2.user_id = o.penyedia_id
          WHERE (o.status_kode = 'disputed' OR o.status_pesanan = 'Dalam Sengketa')
          ORDER BY o.diubah_pada ASC
          LIMIT 1
        `),
        db.query(`
          SELECT
            r.report_id,
            r.alasan,
            r.keterangan,
            r.target_tipe::text AS target_tipe,
            r.dibuat_pada,
            u.nama AS pelapor_nama,
            FLOOR(EXTRACT(EPOCH FROM (NOW() - r.dibuat_pada)) / 3600)::int AS hours_elapsed
          FROM reports r
          JOIN users u ON u.user_id = r.pelapor_id
          WHERE r.status_penanganan != 'Selesai'
            AND r.dibuat_pada <= NOW() - INTERVAL '24 hours'
          ORDER BY r.dibuat_pada ASC
          LIMIT 1
        `),
      ]);

    const userStats = userRes.rows[0] || {};
    const orderStats = orderRes.rows[0] || {};
    const escrowStats = escrowRes.rows[0] || {};
    const listingStats = listingRes.rows[0] || {};
    const barterStats = barterRes.rows[0] || {};
    const reportStats = reportRes.rows[0] || {};

    let slaAlert = null;
    const oldestDispute = slaOrderRes.rows[0];
    const oldestOverdueReport = slaReportRes.rows[0];

    if (oldestDispute) {
      const hrs = Math.max(0, Number(oldestDispute.hours_elapsed || 0));
      slaAlert = {
        case_id: oldestDispute.order_id,
        short_id: shortCode('ORD', oldestDispute.order_id),
        title: oldestDispute.snapshot_judul,
        parties: `${oldestDispute.pelanggan_nama} (Klien) vs ${oldestDispute.penyedia_nama} (Penyedia)`,
        nominal: Number(oldestDispute.harga_kesepakatan || 0),
        hours_elapsed: hrs,
        status: hrs >= 24 ? 'Melebihi SLA 24 Jam' : 'Sengketa Aktif Menunggu Putusan',
        target_tab: 'disputes',
        message: `Pesanan #${shortCode('ORD', oldestDispute.order_id)} (${oldestDispute.pelanggan_nama} vs ${oldestDispute.penyedia_nama}) berstatus sengketa dan menunggu putusan mediasi admin.`,
      };
    } else if (oldestOverdueReport) {
      const hrs = Math.max(24, Number(oldestOverdueReport.hours_elapsed || 24));
      slaAlert = {
        case_id: oldestOverdueReport.report_id,
        short_id: shortCode('REP', oldestOverdueReport.report_id),
        title: oldestOverdueReport.alasan,
        parties: `Pelapor: ${oldestOverdueReport.pelapor_nama} (${oldestOverdueReport.target_tipe})`,
        nominal: 0,
        hours_elapsed: hrs,
        status: 'Melebihi SLA 24 Jam',
        target_tab: oldestOverdueReport.target_tipe === 'Pesanan' || oldestOverdueReport.target_tipe === 'Barter' ? 'disputes' : 'reports',
        message: `Tiket pengaduan #${shortCode('REP', oldestOverdueReport.report_id)} dari ${oldestOverdueReport.pelapor_nama} telah melewati SLA 24 jam (${hrs} jam) dan memerlukan tindak lanjut.`,
      };
    }

    const totalOpenIssues = Number(orderStats.sengketa || 0) + Number(reportStats.terbuka || 0);

    return {
      kpi: {
        pengguna_terverifikasi: {
          label: 'Total Mahasiswa Terdaftar',
          value: Number(userStats.total || 0),
          subtext: `${Number(userStats.terverifikasi || 0)} terverifikasi · ${Number(userStats.belum_terverifikasi || 0)} menunggu`,
          trend: Number(userStats.total || 0) > 0 ? 'up' : 'neutral',
        },
        transaksi_aktif_escrow: {
          label: 'Dana Ditahan Escrow',
          value: formatRupiah(escrowStats.ditahan || 0),
          subtext: `${Number(orderStats.aktif || 0)} order · ${Number(barterStats.aktif || 0)} barter aktif`,
          trend: Number(escrowStats.ditahan || 0) > 0 ? 'up' : 'neutral',
        },
        laporan_dan_sengketa: {
          label: 'Laporan & Sengketa',
          value: `${totalOpenIssues} Perkara`,
          subtext: `${Number(orderStats.sengketa || 0)} sengketa · ${Number(reportStats.terbuka || 0)} aduan terbuka`,
          trend: totalOpenIssues > 0 ? 'danger' : 'up',
        },
        layanan_terdaftar: {
          label: 'Layanan Aktif Katalog',
          value: Number(listingStats.aktif || 0),
          subtext: `${Number(listingStats.total || 0)} total listing tercatat`,
          trend: Number(listingStats.aktif || 0) > 0 ? 'up' : 'neutral',
        },
      },
      summary: {
        escrow_dilepas: Number(escrowStats.dilepas || 0),
        total_barter: Number(barterStats.total || 0),
        order_selesai: Number(orderStats.selesai || 0),
      },
      sla_alert: slaAlert,
      aktivitas_terbaru: recentRes.rows.map((row) => {
        let tone = 'info';
        if (row.prefix === 'ORD') tone = orderStatusTone(row.status_kode, row.status);
        else if (row.prefix === 'BTR') tone = barterStatusTone(row.status_kode);
        else if (row.prefix === 'REP') tone = row.status === 'Selesai' ? 'success' : 'warning';
        else if (row.prefix === 'USR') {
          tone =
            row.status === 'Terverifikasi'
              ? 'success'
              : row.status === 'Ditolak'
              ? 'danger'
              : 'warning';
        }
        return {
          id: shortCode(row.prefix, row.raw_id),
          raw_id: row.raw_id,
          waktu: formatRelativeTime(row.ts),
          timestamp: row.ts,
          tipe: row.tipe,
          entitas: row.entitas,
          keterangan: row.keterangan,
          status: row.status,
          status_tone: tone,
          target_tab: row.target_tab,
        };
      }),
    };
  }

  async getUsers() {
    const { rows } = await db.query(`
      SELECT
        u.user_id,
        u.nama,
        u.email,
        u.peran,
        u.status_verifikasi,
        u.deskripsi_profil,
        u.foto_profil,
        COALESCE(u.status_akun, 'Aktif') AS status_akun,
        u.catatan_sanksi,
        u.dibuat_pada,
        COALESCE(ord.total_orders, 0)::int AS total_orders,
        COALESCE(btr.total_barters, 0)::int AS total_barters,
        COALESCE(lst.total_listings, 0)::int AS total_listings,
        COALESCE(rev.avg_rating, 0)::numeric(3,2) AS avg_rating,
        COALESCE(rev.review_count, 0)::int AS review_count
      FROM users u
      LEFT JOIN (
        SELECT user_id, COUNT(*)::int AS total_orders FROM (
          SELECT pelanggan_id AS user_id FROM orders
          UNION ALL
          SELECT penyedia_id AS user_id FROM orders WHERE penyedia_id <> pelanggan_id
        ) x GROUP BY user_id
      ) ord ON ord.user_id = u.user_id
      LEFT JOIN (
        SELECT user_id, COUNT(*)::int AS total_barters FROM (
          SELECT pengaju_id AS user_id FROM barter_agreements
          UNION ALL
          SELECT penerima_id AS user_id FROM barter_agreements WHERE penerima_id <> pengaju_id
        ) y GROUP BY user_id
      ) btr ON btr.user_id = u.user_id
      LEFT JOIN (
        SELECT penyedia_id, COUNT(*)::int AS total_listings
        FROM service_listings
        GROUP BY penyedia_id
      ) lst ON lst.penyedia_id = u.user_id
      LEFT JOIN (
        SELECT penerima_id, ROUND(AVG(rating)::numeric, 2) AS avg_rating, COUNT(*)::int AS review_count
        FROM reviews
        WHERE status_moderasi = 'Tampil'
        GROUP BY penerima_id
      ) rev ON rev.penerima_id = u.user_id
      ORDER BY u.dibuat_pada DESC
    `);

    return rows.map((u) => ({
      user_id: u.user_id,
      nama: u.nama,
      email: u.email,
      peran: u.peran,
      kampus: CAMPUS_LABEL,
      deskripsi_profil: u.deskripsi_profil || '',
      foto_profil: u.foto_profil || null,
      status_verifikasi: u.status_verifikasi,
      status_akun: u.status_akun || 'Aktif',
      catatan_sanksi: u.catatan_sanksi || null,
      jumlah_transaksi: Number(u.total_orders || 0) + Number(u.total_barters || 0),
      jumlah_order: Number(u.total_orders || 0),
      jumlah_barter: Number(u.total_barters || 0),
      jumlah_layanan: Number(u.total_listings || 0),
      rating: Number(u.avg_rating || 0),
      jumlah_ulasan: Number(u.review_count || 0),
      dibuat_pada: u.dibuat_pada,
    }));
  }

  async verifyUser(userId, status, notes, adminId) {
    if (!isUuid(userId)) {
      throw new AppError('ID pengguna harus berupa UUID yang valid.', 400, 'INVALID_UUID');
    }

    const { rows: existing } = await db.query(
      'SELECT user_id, status_verifikasi FROM users WHERE user_id = $1 LIMIT 1',
      [userId]
    );
    if (existing.length === 0) {
      throw new AppError('Pengguna tidak ditemukan di database.', 404, 'USER_NOT_FOUND');
    }

    const allowed = ['Terverifikasi', 'Ditolak', 'Belum Terverifikasi'];
    const targetStatus = allowed.includes(status)
      ? status
      : status === 'Terverifikasi'
      ? 'Terverifikasi'
      : 'Ditolak';

    const { rows: updated } = await db.query(
      `UPDATE users
       SET status_verifikasi = $1
       WHERE user_id = $2
       RETURNING user_id, nama, email, status_verifikasi, COALESCE(status_akun, 'Aktif') AS status_akun`,
      [targetStatus, userId]
    );

    await this.writeAuditLog({
      aktorId: adminId,
      aksi: 'VERIFIKASI_KTM',
      objekTipe: 'users',
      objekId: userId,
      statusSebelum: existing[0].status_verifikasi,
      statusSesudah: `${targetStatus}${notes ? `: ${notes}` : ''}`.slice(0, 100),
    });

    return {
      ...updated[0],
      catatan: notes || null,
      diverifikasi_pada: new Date().toISOString(),
    };
  }

  async sanctionUser(userId, sanctionType, notes, adminId) {
    if (!isUuid(userId)) {
      throw new AppError('ID pengguna harus berupa UUID yang valid.', 400, 'INVALID_UUID');
    }

    const { rows: existing } = await db.query(
      "SELECT user_id, COALESCE(status_akun, 'Aktif') AS status_akun FROM users WHERE user_id = $1 LIMIT 1",
      [userId]
    );
    if (existing.length === 0) {
      throw new AppError('Pengguna tidak ditemukan di database.', 404, 'USER_NOT_FOUND');
    }

    const statusAkun =
      sanctionType === 'Blokir Permanen'
        ? 'Diblokir Permanen'
        : sanctionType === 'Bekukan Akun Sementara (7 Hari)'
        ? 'Dibekukan Sementara (7 Hari)'
        : sanctionType === 'Pulihkan Akun (Aktif)' || sanctionType === 'Aktif'
        ? 'Aktif'
        : 'Peringatan Resmi';

    const cleanNotes = notes ? String(notes).trim() : null;

    await db.query(
      `UPDATE users
       SET status_akun = $1,
           catatan_sanksi = $2
       WHERE user_id = $3`,
      [statusAkun, statusAkun === 'Aktif' ? null : cleanNotes, userId]
    );

    await this.writeAuditLog({
      aktorId: adminId,
      aksi: 'SANKSI_PENGGUNA',
      objekTipe: 'users',
      objekId: userId,
      statusSebelum: existing[0].status_akun,
      statusSesudah: `${statusAkun}${cleanNotes ? `: ${cleanNotes}` : ''}`.slice(0, 100),
    });

    return {
      user_id: userId,
      sanction: sanctionType,
      status_akun: statusAkun,
      catatan: cleanNotes,
      tanggal: new Date().toISOString(),
    };
  }

  async getListings() {
    const { rows } = await db.query(`
      SELECT
        sl.listing_id,
        sl.judul,
        sl.deskripsi,
        sl.harga,
        sl.status,
        sl.tipe_penawaran,
        sl.deskripsi_imbalan_barter,
        sl.dibuat_pada,
        u.user_id AS penyedia_id,
        u.nama AS penyedia_nama,
        u.email AS penyedia_email,
        u.foto_profil AS penyedia_foto,
        s.nama_keterampilan,
        s.kategori,
        COALESCE(rev.avg_rating, 0)::numeric(3,2) AS rating,
        COALESCE(rev.review_count, 0)::int AS ulasan_count,
        (
          EXISTS (
            SELECT 1 FROM orders o
            WHERE o.listing_id = sl.listing_id
              AND o.status_kode IN ('accepted','in_progress','completion_requested','completed')
          ) OR EXISTS (
            SELECT 1 FROM barter_agreements b
            WHERE (b.listing_id = sl.listing_id OR b.listing_pengaju_id = sl.listing_id)
              AND b.status_kode IN ('accepted','in_progress','completion_requested','completed')
          )
        ) AS sedang_terkunci
      FROM service_listings sl
      JOIN users u ON sl.penyedia_id = u.user_id
      JOIN skills s ON sl.skill_id = s.skill_id
      LEFT JOIN (
        SELECT penerima_id, ROUND(AVG(rating)::numeric, 2) AS avg_rating, COUNT(*)::int AS review_count
        FROM reviews
        WHERE status_moderasi = 'Tampil'
        GROUP BY penerima_id
      ) rev ON rev.penerima_id = sl.penyedia_id
      ORDER BY sl.dibuat_pada DESC
    `);

    return rows.map((g) => {
      const flagged = isAcademicViolation(`${g.judul} ${g.deskripsi}`);
      return {
        listing_id: g.listing_id,
        judul: g.judul,
        deskripsi: g.deskripsi,
        penyedia_id: g.penyedia_id,
        penyedia_nama: g.penyedia_nama,
        penyedia_email: g.penyedia_email,
        penyedia_foto: g.penyedia_foto || null,
        kategori: g.kategori || 'Lainnya',
        nama_keterampilan: g.nama_keterampilan,
        tipe_penawaran: g.tipe_penawaran,
        deskripsi_imbalan_barter: g.deskripsi_imbalan_barter || null,
        harga: Number(g.harga || 0),
        rating: Number(g.rating || 0),
        ulasan_count: Number(g.ulasan_count || 0),
        status: g.status,
        sedang_terkunci: Boolean(g.sedang_terkunci),
        indikasi_pelanggaran: flagged
          ? 'Terdeteksi kata kunci pelanggaran integritas akademik (Anti-Joki)'
          : null,
        dibuat_pada: g.dibuat_pada,
      };
    });
  }

  async moderateListing(listingId, action, notes, adminId) {
    if (!isUuid(listingId)) {
      throw new AppError('ID layanan harus berupa UUID yang valid.', 400, 'INVALID_UUID');
    }

    const { rows: existing } = await db.query(
      'SELECT listing_id, status FROM service_listings WHERE listing_id = $1 LIMIT 1',
      [listingId]
    );
    if (existing.length === 0) {
      throw new AppError('Layanan tidak ditemukan di database.', 404, 'LISTING_NOT_FOUND');
    }

    const statusMap = {
      'Takedown Segera': 'Disembunyikan Moderasi',
      'Hapus Permanen': 'Nonaktif',
      'Peringatan Penyedia': 'Disembunyikan Moderasi',
      'Aktifkan Kembali': 'Aktif',
    };
    const targetStatus = statusMap[action] || 'Disembunyikan Moderasi';

    await db.query(
      'UPDATE service_listings SET status = $1, diubah_pada = NOW() WHERE listing_id = $2',
      [targetStatus, listingId]
    );

    await this.writeAuditLog({
      aktorId: adminId,
      aksi: 'MODERASI_GIG',
      objekTipe: 'service_listings',
      objekId: listingId,
      statusSebelum: existing[0].status,
      statusSesudah: `${action} -> ${targetStatus}`.slice(0, 100),
    });

    return {
      listing_id: listingId,
      action,
      status_terbaru: targetStatus,
      catatan: notes || null,
      tanggal: new Date().toISOString(),
    };
  }

  async getDisputes() {
    const [orderDisputesRes, reportDisputesRes] = await Promise.all([
      db.query(`
        SELECT
          o.order_id,
          o.snapshot_judul,
          o.harga_kesepakatan,
          o.catatan_kebutuhan,
          o.ruang_lingkup,
          o.status_pesanan,
          o.status_kode,
          o.dibuat_pada,
          o.diubah_pada,
          COALESCE(p.nominal, o.harga_kesepakatan, 0) AS nilai_escrow,
          COALESCE(p.status_pembayaran::text, 'Belum Bayar') AS status_pembayaran,
          u1.user_id AS klien_id, u1.nama AS klien_nama, u1.email AS klien_email, u1.foto_profil AS klien_foto,
          u2.user_id AS penyedia_id, u2.nama AS penyedia_nama, u2.email AS penyedia_email, u2.foto_profil AS penyedia_foto
        FROM orders o
        JOIN users u1 ON u1.user_id = o.pelanggan_id
        JOIN users u2 ON u2.user_id = o.penyedia_id
        LEFT JOIN payments p ON p.order_id = o.order_id
        WHERE o.status_kode = 'disputed' OR o.status_pesanan = 'Dalam Sengketa'
        ORDER BY o.diubah_pada ASC
      `),
      db.query(`
        SELECT
          r.report_id,
          r.target_tipe::text AS target_tipe,
          r.target_id,
          r.alasan,
          r.keterangan,
          r.status_penanganan::text AS status_penanganan,
          r.dibuat_pada,
          rep.nama AS pelapor_nama,
          rep.email AS pelapor_email,
          o.order_id AS matched_order_id,
          o.snapshot_judul AS order_judul,
          o.harga_kesepakatan AS order_harga,
          o.ruang_lingkup AS order_ruang_lingkup,
          o.status_kode AS order_status_kode,
          COALESCE(p.nominal, o.harga_kesepakatan, 0) AS order_escrow,
          uk.nama AS order_klien_nama, uk.email AS order_klien_email, uk.foto_profil AS order_klien_foto,
          up.nama AS order_penyedia_nama, up.email AS order_penyedia_email, up.foto_profil AS order_penyedia_foto,
          b.barter_id AS matched_barter_id,
          b.deskripsi_jasa_pengaju,
          b.deskripsi_jasa_penerima,
          b.status_kode AS barter_status_kode,
          ub1.nama AS barter_pengaju_nama, ub1.email AS barter_pengaju_email, ub1.foto_profil AS barter_pengaju_foto,
          ub2.nama AS barter_penerima_nama, ub2.email AS barter_penerima_email, ub2.foto_profil AS barter_penerima_foto
        FROM reports r
        JOIN users rep ON rep.user_id = r.pelapor_id
        LEFT JOIN orders o ON r.target_tipe = 'Pesanan' AND o.order_id = r.target_id
        LEFT JOIN payments p ON p.order_id = o.order_id
        LEFT JOIN users uk ON uk.user_id = o.pelanggan_id
        LEFT JOIN users up ON up.user_id = o.penyedia_id
        LEFT JOIN barter_agreements b ON r.target_tipe = 'Barter' AND b.barter_id = r.target_id
        LEFT JOIN users ub1 ON ub1.user_id = b.pengaju_id
        LEFT JOIN users ub2 ON ub2.user_id = b.penerima_id
        WHERE r.target_tipe IN ('Pesanan', 'Barter')
          AND r.status_penanganan != 'Selesai'
        ORDER BY r.dibuat_pada ASC
      `),
    ]);

    const seenOrderIds = new Set();
    const cases = [];

    for (const o of orderDisputesRes.rows) {
      seenOrderIds.add(o.order_id);
      const nominal = Number(o.nilai_escrow || 0);
      cases.push({
        case_id: o.order_id,
        short_id: shortCode('ORD', o.order_id),
        tipe_transaksi: 'Pesanan',
        judul_layanan: o.snapshot_judul,
        nilai_escrow: nominal,
        status_escrow: `${o.status_pembayaran} (Simulasi Escrow)`,
        status_perkara: 'Sengketa Pesanan Aktif',
        rekomendasi_sistem: `Split 50:50 (${formatRupiah(nominal / 2)} Klien / ${formatRupiah(nominal / 2)} Penyedia)`,
        dibuat_pada: o.diubah_pada || o.dibuat_pada,
        bukti_urls: extractUrls(`${o.catatan_kebutuhan} ${o.ruang_lingkup}`),
        klien: {
          nama: o.klien_nama,
          email: o.klien_email,
          foto_profil: o.klien_foto || null,
          argumen: o.catatan_kebutuhan || 'Pesanan ditandai sengketa untuk mediasi admin.',
          tuntutan: `Tinjauan Escrow (${formatRupiah(nominal)})`,
        },
        penyedia: {
          nama: o.penyedia_nama,
          email: o.penyedia_email,
          foto_profil: o.penyedia_foto || null,
          argumen: o.ruang_lingkup || 'Sesuai ruang lingkup layanan yang disepakati.',
          tuntutan: `Pencairan Penyedia (${formatRupiah(nominal)})`,
        },
      });
    }

    for (const r of reportDisputesRes.rows) {
      if (r.matched_order_id && seenOrderIds.has(r.matched_order_id)) continue;

      if (r.target_tipe === 'Barter') {
        cases.push({
          case_id: r.report_id,
          short_id: shortCode('BTR', r.matched_barter_id || r.report_id),
          tipe_transaksi: 'Barter',
          judul_layanan: r.alasan || 'Komplain Transaksi Smart Barter',
          nilai_escrow: 0,
          status_escrow: 'Smart Barter Non-Tunai (Rp 0)',
          status_perkara: `Laporan Barter (${r.status_penanganan})`,
          rekomendasi_sistem: 'Mediasi Timbal Balik atau Pembatalan Kontrak Barter',
          dibuat_pada: r.dibuat_pada,
          bukti_urls: extractUrls(r.keterangan),
          klien: {
            nama: r.barter_pengaju_nama || r.pelapor_nama,
            email: r.barter_pengaju_email || r.pelapor_email,
            foto_profil: r.barter_pengaju_foto || null,
            argumen: r.keterangan,
            tuntutan: r.deskripsi_jasa_pengaju || 'Evaluasi kewajiban pihak pengaju',
          },
          penyedia: {
            nama: r.barter_penerima_nama || 'Mitra Barter',
            email: r.barter_penerima_email || '-',
            foto_profil: r.barter_penerima_foto || null,
            argumen: r.deskripsi_jasa_penerima || 'Menunggu klarifikasi mitra lawan',
            tuntutan: 'Penyelesaian Adil Tanpa Dana Tunai',
          },
        });
      } else {
        const nominal = Number(r.order_escrow || 0);
        cases.push({
          case_id: r.report_id,
          short_id: shortCode('REP', r.report_id),
          tipe_transaksi: 'Pesanan',
          judul_layanan: r.order_judul || r.alasan,
          nilai_escrow: nominal,
          status_escrow: nominal > 0 ? 'Simulasi Escrow Aktif' : 'Belum Ada Dana Escrow',
          status_perkara: `Laporan Komplain Pesanan (${r.status_penanganan})`,
          rekomendasi_sistem:
            nominal > 0
              ? `Split 50:50 (${formatRupiah(nominal / 2)} Klien / ${formatRupiah(nominal / 2)} Penyedia)`
              : 'Mediasi Penyesuaian Status Pesanan',
          dibuat_pada: r.dibuat_pada,
          bukti_urls: extractUrls(r.keterangan),
          klien: {
            nama: r.order_klien_nama || r.pelapor_nama,
            email: r.order_klien_email || r.pelapor_email,
            foto_profil: r.order_klien_foto || null,
            argumen: r.keterangan,
            tuntutan: r.alasan,
          },
          penyedia: {
            nama: r.order_penyedia_nama || 'Penyedia Terkait',
            email: r.order_penyedia_email || '-',
            foto_profil: r.order_penyedia_foto || null,
            argumen: r.order_ruang_lingkup || 'Menunggu keterangan penyedia.',
            tuntutan: nominal > 0 ? `Pencairan (${formatRupiah(nominal)})` : 'Klarifikasi Ruang Lingkup',
          },
        });
      }
    }

    return cases;
  }

  async resolveDispute(caseId, verdictType, considerationNotes, adminId) {
    if (!isUuid(caseId)) {
      throw new AppError('ID perkara sengketa harus berupa UUID yang valid.', 400, 'INVALID_UUID');
    }

    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      let orderRow = null;
      let barterRow = null;
      let reportRow = null;

      const { rows: directOrders } = await client.query(
        'SELECT order_id, harga_kesepakatan FROM orders WHERE order_id = $1 LIMIT 1',
        [caseId]
      );
      if (directOrders.length > 0) {
        orderRow = directOrders[0];
      } else {
        const { rows: directReports } = await client.query(
          'SELECT report_id, target_tipe::text AS target_tipe, target_id FROM reports WHERE report_id = $1 LIMIT 1',
          [caseId]
        );
        if (directReports.length > 0) {
          reportRow = directReports[0];
          if (reportRow.target_tipe === 'Pesanan') {
            const { rows: ord } = await client.query(
              'SELECT order_id, harga_kesepakatan FROM orders WHERE order_id = $1 LIMIT 1',
              [reportRow.target_id]
            );
            orderRow = ord[0] || null;
          } else if (reportRow.target_tipe === 'Barter') {
            const { rows: btr } = await client.query(
              'SELECT barter_id FROM barter_agreements WHERE barter_id = $1 LIMIT 1',
              [reportRow.target_id]
            );
            barterRow = btr[0] || null;
          }
        }
      }

      if (!orderRow && !barterRow && !reportRow) {
        throw new AppError('Perkara sengketa tidak ditemukan di database.', 404, 'DISPUTE_NOT_FOUND');
      }

      const nominal = Number(orderRow?.harga_kesepakatan || 0);
      const verdictMapping = {
        REFUND_100: {
          label: 'Pengembalian Penuh ke Klien (Refund 100%)',
          pembagian: { klien: nominal, penyedia: 0 },
          orderKode: 'cancelled',
          orderLabel: 'Dibatalkan',
          barterKode: 'cancelled',
          barterLabel: 'Dibatalkan',
          escrowLabel: 'Dikembalikan (Simulasi)',
        },
        RELEASE_100: {
          label: 'Pelepasan Penuh ke Penyedia (Release 100%)',
          pembagian: { klien: 0, penyedia: nominal },
          orderKode: 'completed',
          orderLabel: 'Selesai',
          barterKode: 'completed',
          barterLabel: 'Selesai',
          escrowLabel: 'Dilepas (Simulasi)',
        },
        SPLIT_50_50: {
          label: 'Putusan Berimbang Split 50:50',
          pembagian: { klien: Math.floor(nominal / 2), penyedia: nominal - Math.floor(nominal / 2) },
          orderKode: 'completed',
          orderLabel: 'Selesai',
          barterKode: 'completed',
          barterLabel: 'Selesai',
          escrowLabel: 'Dilepas (Split 50:50 Simulasi)',
        },
      };

      const chosen = verdictMapping[verdictType] || verdictMapping.SPLIT_50_50;
      const reasonText = (considerationNotes || 'Putusan arbitrase administrator kampus').trim();

      if (orderRow) {
        await client.query(
          `UPDATE orders
           SET status_kode = $1,
               status_pesanan = $2,
               alasan_pembatalan = CASE WHEN $1 = 'cancelled' THEN $3 ELSE alasan_pembatalan END,
               dikonfirmasi_selesai_pada = CASE WHEN $1 = 'completed' THEN COALESCE(dikonfirmasi_selesai_pada, NOW()) ELSE dikonfirmasi_selesai_pada END,
               diubah_pada = NOW()
           WHERE order_id = $4`,
          [chosen.orderKode, chosen.orderLabel, reasonText, orderRow.order_id]
        );
        await client.query(
          `UPDATE payments
           SET catatan_simulasi = $1,
               diubah_pada = NOW()
           WHERE order_id = $2`,
          [`Putusan Admin (${chosen.label}): ${reasonText}`, orderRow.order_id]
        );
        await client.query(
          `UPDATE reports
           SET status_penanganan = 'Selesai',
               keputusan = $1,
               ditangani_oleh = $2,
               diselesaikan_pada = NOW()
           WHERE target_tipe = 'Pesanan' AND target_id = $3 AND status_penanganan != 'Selesai'`,
          [`${chosen.label}: ${reasonText}`, isUuid(adminId) ? adminId : null, orderRow.order_id]
        );
      }

      if (barterRow) {
        await client.query(
          `UPDATE barter_agreements
           SET status_kode = $1,
               status = $2,
               alasan_pembatalan = CASE WHEN $1 = 'cancelled' THEN $3 ELSE alasan_pembatalan END,
               diubah_pada = NOW()
           WHERE barter_id = $4`,
          [chosen.barterKode, chosen.barterLabel, reasonText, barterRow.barter_id]
        );
      }

      if (reportRow) {
        await client.query(
          `UPDATE reports
           SET status_penanganan = 'Selesai',
               keputusan = $1,
               ditangani_oleh = $2,
               diselesaikan_pada = NOW()
           WHERE report_id = $3`,
          [`${chosen.label}: ${reasonText}`, isUuid(adminId) ? adminId : null, reportRow.report_id]
        );
      }

      await client.query(
        `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sesudah)
         VALUES ($1, 'PUTUSAN_ARBITRASE_SENGKETA', $2, $3, $4)`,
        [
          isUuid(adminId) ? adminId : null,
          orderRow ? 'orders' : barterRow ? 'barter_agreements' : 'reports',
          orderRow?.order_id || barterRow?.barter_id || reportRow.report_id,
          chosen.label.slice(0, 100),
        ]
      );

      await client.query('COMMIT');

      return {
        case_id: caseId,
        verdict_code: verdictType,
        putusan_resmi: chosen.label,
        pembagian_saldo: chosen.pembagian,
        status_pesanan: orderRow ? chosen.orderLabel : chosen.barterLabel,
        status_escrow: orderRow ? chosen.escrowLabel : 'Smart Barter Non-Tunai',
        catatan_pertimbangan: reasonText,
        dieksekusi_pada: new Date().toISOString(),
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async getReports() {
    const { rows } = await db.query(`
      SELECT
        r.report_id,
        r.target_tipe::text AS target_tipe,
        r.target_id,
        r.alasan,
        r.keterangan,
        r.status_penanganan::text AS status_penanganan,
        r.keputusan,
        r.dibuat_pada,
        r.diselesaikan_pada,
        u.nama AS pelapor_nama,
        u.email AS pelapor_email,
        adm.nama AS admin_nama,
        o.snapshot_judul AS order_judul,
        b.deskripsi_jasa_pengaju AS barter_judul,
        sl.judul AS listing_judul,
        tu.nama AS target_user_nama
      FROM reports r
      JOIN users u ON r.pelapor_id = u.user_id
      LEFT JOIN users adm ON r.ditangani_oleh = adm.user_id
      LEFT JOIN orders o ON r.target_tipe = 'Pesanan' AND o.order_id = r.target_id
      LEFT JOIN barter_agreements b ON r.target_tipe = 'Barter' AND b.barter_id = r.target_id
      LEFT JOIN service_listings sl ON r.target_tipe = 'Listing' AND sl.listing_id = r.target_id
      LEFT JOIN users tu ON r.target_tipe = 'Pengguna' AND tu.user_id = r.target_id
      ORDER BY r.dibuat_pada DESC
    `);

    return rows.map((r) => {
      const targetContext =
        r.order_judul || r.listing_judul || r.target_user_nama || (r.barter_judul ? `Barter: ${r.barter_judul}` : null);
      const urls = extractUrls(r.keterangan);
      const statusLabel = r.status_penanganan;
      const urgent = /bypass|joki|penipuan|tipu/i.test(`${r.alasan} ${r.keterangan}`);
      return {
        report_id: r.report_id,
        short_id: shortCode('REP', r.report_id),
        prioritas: urgent ? 'Tinggi' : 'Sedang',
        pelapor_nama: r.pelapor_nama,
        pelapor_email: r.pelapor_email,
        target_tipe: r.target_tipe,
        target_id: r.target_id,
        target_ringkas: targetContext || shortCode('REF', r.target_id),
        kategori: r.alasan,
        deskripsi: r.keterangan,
        bukti_urls: urls,
        status_tiket: statusLabel,
        status_penanganan: r.status_penanganan,
        keputusan: r.keputusan || null,
        admin_nama: r.admin_nama || null,
        dibuat_pada: r.dibuat_pada,
        diselesaikan_pada: r.diselesaikan_pada,
      };
    });
  }

  async resolveReport(reportId, action, notes, adminId) {
    if (!isUuid(reportId)) {
      throw new AppError('ID laporan harus berupa UUID yang valid.', 400, 'INVALID_UUID');
    }

    const { rows: existing } = await db.query(
      'SELECT report_id, status_penanganan::text AS status_penanganan FROM reports WHERE report_id = $1 LIMIT 1',
      [reportId]
    );
    if (existing.length === 0) {
      throw new AppError('Tiket laporan tidak ditemukan di database.', 404, 'REPORT_NOT_FOUND');
    }

    const targetStatus = action === 'Tandai Ditinjau' || action === 'Ditinjau' ? 'Ditinjau' : 'Selesai';
    const decisionText = `${action}${notes ? `: ${String(notes).trim()}` : ''}`;

    const { rows } = await db.query(
      `UPDATE reports
       SET status_penanganan = $1,
           keputusan = $2,
           ditangani_oleh = $3,
           diselesaikan_pada = CASE WHEN $1 = 'Selesai' THEN NOW() ELSE diselesaikan_pada END
       WHERE report_id = $4
       RETURNING report_id, status_penanganan::text AS status_penanganan, keputusan, diselesaikan_pada`,
      [targetStatus, decisionText, isUuid(adminId) ? adminId : null, reportId]
    );

    await this.writeAuditLog({
      aktorId: adminId,
      aksi: 'TINDAK_LANJUT_LAPORAN',
      objekTipe: 'reports',
      objekId: reportId,
      statusSebelum: existing[0].status_penanganan,
      statusSesudah: targetStatus,
    });

    return {
      report_id: reportId,
      tindakan_diambil: action,
      catatan_petugas: notes || null,
      status_tiket: rows[0].status_penanganan,
      status_penanganan: rows[0].status_penanganan,
      keputusan: rows[0].keputusan,
      diselesaikan_pada: rows[0].diselesaikan_pada,
    };
  }

  async getEscrowTransactions() {
    const [ordersRes, bartersRes] = await Promise.all([
      db.query(`
        SELECT
          o.order_id,
          o.snapshot_judul,
          o.harga_kesepakatan,
          o.status_pesanan,
          o.status_kode,
          o.dibuat_pada,
          o.diubah_pada,
          p.nominal AS payment_nominal,
          p.status_kode AS payment_status_kode,
          p.status_pembayaran::text AS payment_status_label,
          p.referensi_simulasi,
          u1.nama AS pelanggan_nama,
          u2.nama AS penyedia_nama
        FROM orders o
        JOIN users u1 ON u1.user_id = o.pelanggan_id
        JOIN users u2 ON u2.user_id = o.penyedia_id
        LEFT JOIN payments p ON p.order_id = o.order_id
        ORDER BY o.diubah_pada DESC
      `),
      db.query(`
        SELECT
          b.barter_id,
          b.status,
          b.status_kode,
          b.deskripsi_jasa_pengaju,
          b.deskripsi_jasa_penerima,
          b.dibuat_pada,
          b.diubah_pada,
          u1.nama AS pengaju_nama,
          u2.nama AS penerima_nama
        FROM barter_agreements b
        JOIN users u1 ON u1.user_id = b.pengaju_id
        JOIN users u2 ON u2.user_id = b.penerima_id
        ORDER BY b.diubah_pada DESC
      `),
    ]);

    let heldTotal = 0;
    let releasedTotal = 0;

    const orderItems = ordersRes.rows.map((o) => {
      const nominalNum = Number(o.payment_nominal ?? o.harga_kesepakatan ?? 0);
      const isPaid = o.payment_status_kode === 'success';
      const code = o.status_kode;

      let statusEscrow = 'Belum Dibayar';
      if (isPaid) {
        if (code === 'completed') {
          statusEscrow = 'Dilepas ke Penyedia';
          releasedTotal += nominalNum;
        } else if (code === 'cancelled' || code === 'rejected') {
          statusEscrow = 'Dikembalikan ke Klien';
        } else if (code === 'disputed' || o.status_pesanan === 'Dalam Sengketa') {
          statusEscrow = 'Dibekukan (Sengketa)';
          heldTotal += nominalNum;
        } else if (code === 'in_progress' || code === 'completion_requested') {
          statusEscrow = 'Ditahan Simulasi (Escrow)';
          heldTotal += nominalNum;
        } else {
          statusEscrow = o.payment_status_label || 'Tercatat';
        }
      }

      return {
        id: shortCode('ORD', o.order_id),
        raw_id: o.order_id,
        jenis: 'Escrow Berbayar',
        judul: o.snapshot_judul,
        pihak: `${o.pelanggan_nama} → ${o.penyedia_nama}`,
        nominal: formatRupiah(nominalNum),
        nominal_angka: nominalNum,
        referensi: o.referensi_simulasi || '-',
        status_escrow: statusEscrow,
        status_pesanan: o.status_pesanan,
        status_kode: code,
        tanggal: formatDateId(o.diubah_pada || o.dibuat_pada),
        sort_ts: new Date(o.diubah_pada || o.dibuat_pada).getTime(),
      };
    });

    const barterItems = bartersRes.rows.map((b) => ({
      id: shortCode('BTR', b.barter_id),
      raw_id: b.barter_id,
      jenis: 'Smart Barter Rp 0',
      judul: b.deskripsi_jasa_penerima,
      pihak: `${b.pengaju_nama} ↔ ${b.penerima_nama}`,
      nominal: 'Rp 0 (Barter)',
      nominal_angka: 0,
      referensi: 'SIMETRIS-RP0',
      status_escrow: b.status_kode === 'completed' ? 'Barter Tuntas 2 Pihak' : 'Smart Barter Non-Tunai',
      status_pesanan: b.status,
      status_kode: b.status_kode,
      tanggal: formatDateId(b.diubah_pada || b.dibuat_pada),
      sort_ts: new Date(b.diubah_pada || b.dibuat_pada).getTime(),
    }));

    const transaksi = [...orderItems, ...barterItems].sort((a, b) => b.sort_ts - a.sort_ts);

    return {
      saldo_penampungan_live: formatRupiah(heldTotal),
      saldo_penampungan_angka: heldTotal,
      saldo_dilepas_total: formatRupiah(releasedTotal),
      saldo_dilepas_angka: releasedTotal,
      jumlah_order: orderItems.length,
      jumlah_barter: barterItems.length,
      badge_status: '100% LIVE · SIMULASI ESCROW & BARTER',
      transaksi,
    };
  }
}

module.exports = new AdminService();
