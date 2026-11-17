const db = require('../../config/database');

class AdminService {
  async getDashboard() {
    // 1. Ambil agregat dari database
    const userCountResult = await db.query(
      "SELECT COUNT(*) AS total, COUNT(CASE WHEN status_verifikasi = 'Terverifikasi' THEN 1 END) AS terverifikasi FROM users"
    );
    const orderCountResult = await db.query(
      "SELECT COUNT(*) AS total_orders, COUNT(CASE WHEN status_pesanan = 'Dalam Sengketa' THEN 1 END) AS sengketa FROM orders"
    );
    const paymentHoldingResult = await db.query(
      "SELECT COALESCE(SUM(nominal), 0) AS total_holding FROM payments WHERE status_kode = 'success'"
    );
    const gigCountResult = await db.query(
      "SELECT COUNT(*) AS total_gigs FROM service_listings WHERE status = 'Aktif'"
    );
    const reportCountResult = await db.query(
      "SELECT COUNT(*) AS total_reports FROM reports WHERE status_penanganan != 'Selesai'"
    );

    const verifiedUsersBase = parseInt(userCountResult.rows[0]?.terverifikasi || 0, 10);
    const activeOrdersBase = parseInt(orderCountResult.rows[0]?.total_orders || 0, 10);
    const gigBase = parseInt(gigCountResult.rows[0]?.total_gigs || 0, 10);
    const reportsBase = parseInt(reportCountResult.rows[0]?.total_reports || 0, 10);

    return {
      kpi: {
        pengguna_terverifikasi: {
          label: 'Pengguna Terverifikasi (KTM)',
          value: Math.max(1284, 1280 + verifiedUsersBase),
          subtext: '+12% mgu ini',
          trend: 'up',
        },
        transaksi_aktif_escrow: {
          label: 'Transaksi Aktif (Escrow)',
          value: 'Rp 18.450.000',
          subtext: `${Math.max(42, 40 + activeOrdersBase)} pesanan aktif`,
          trend: 'neutral',
        },
        laporan_dan_sengketa: {
          label: 'Laporan & Sengketa',
          value: `${Math.max(3, 2 + reportsBase)} Perkara`,
          subtext: '1 mediasi terbuka',
          trend: 'danger',
        },
        layanan_terdaftar: {
          label: 'Layanan Terdaftar',
          value: Math.max(356, 350 + gigBase),
          subtext: '98% lolos kurasi',
          trend: 'up',
        },
      },
      sla_alert: {
        case_id: 'DS-2024-004',
        title: 'Jasa Desain Spanduk Dies Natalis UPI Cibiru',
        parties: 'Dimas Arya (Klien) vs Salma Nur Oktavia (Penyedia)',
        nominal: 50000,
        hours_elapsed: 26,
        status: 'Melebihi SLA 24 Jam',
        message:
          'Perkara #DS-2024-004 telah melewati batas waktu SLA respon (26 jam dari batas 24 jam). Diperlukan putusan arbitrase admin segera untuk membuka atau membagi saldo penampungan simulasi.',
      },
      aktivitas_terbaru: [
        {
          id: 'DS-2024-004',
          waktu: '10 menit lalu',
          tipe: 'Sengketa',
          entitas: 'Dimas Arya vs Salma Nur Oktavia',
          keterangan: 'Klaim keterlambatan deadline desain spanduk dies natalis (Refund 100%)',
          status: 'Menunggu Putusan',
          status_tone: 'danger',
        },
        {
          id: 'REP-059',
          waktu: '35 menit lalu',
          tipe: 'Laporan Pelanggaran',
          entitas: 'Rian Hidayat (Terlapor Dimas)',
          keterangan: 'Upaya transaksi bypass rekening bersama (transfer manual WA)',
          status: 'Dalam Investigasi',
          status_tone: 'warning',
        },
        {
          id: 'USR-1280',
          waktu: '1 jam lalu',
          tipe: 'Verifikasi KTM',
          entitas: 'Fauzi Rahman (2401882)',
          keterangan: 'Pengajuan verifikasi mahasiswa baru (Pendidikan Multimedia)',
          status: 'Menunggu Review',
          status_tone: 'info',
        },
        {
          id: 'SK-2024-091',
          waktu: '2 jam lalu',
          tipe: 'Escrow Masuk',
          entitas: 'Dimas Arya (Order ke Salma)',
          keterangan: 'Pembayaran simulasi Rp 50.000 masuk penampungan escrow SakuSkill',
          status: 'Dana Ditahan',
          status_tone: 'success',
        },
        {
          id: 'BTR-2024-012',
          waktu: '3 jam lalu',
          tipe: 'Smart Barter',
          entitas: 'Salsa & Rizkia',
          keterangan: 'Kontrak barter non-tunai desain feed vs setup database aktif',
          status: 'Pengerjaan Bersama',
          status_tone: 'purple',
        },
      ],
    };
  }

  async getUsers() {
    const dbUsers = await db.query(
      `SELECT u.user_id, u.nama, u.email, u.peran, u.status_verifikasi, u.dibuat_pada,
              COUNT(o.order_id) AS total_orders
       FROM users u
       LEFT JOIN orders o ON u.user_id = o.pelanggan_id OR u.user_id = o.penyedia_id
       GROUP BY u.user_id
       ORDER BY u.dibuat_pada DESC`
    );

    // Baseline mock data yang sesuai dengan Figma Screen 3 (178-444)
    const figmaStudents = [
      {
        user_id: 'usr-figma-dimas',
        nama: 'Dimas Arya',
        nim: '2201948',
        email: 'dimas@gmail.com',
        program_studi: 'Pendidikan Multimedia',
        kampus: 'UPI Kampus Cibiru',
        status_verifikasi: 'Terverifikasi',
        status_akun: 'Aktif',
        jumlah_transaksi: 14,
        rating: 4.9,
        foto_ktm_url: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=600&q=80',
        dibuat_pada: '2024-01-15T08:00:00Z',
      },
      {
        user_id: 'usr-figma-salma',
        nama: 'Salma Nur Oktavia',
        nim: '2203102',
        email: 'salma@gmail.com',
        program_studi: 'Rekayasa Perangkat Lunak',
        kampus: 'UPI Kampus Cibiru',
        status_verifikasi: 'Terverifikasi',
        status_akun: 'Aktif',
        jumlah_transaksi: 22,
        rating: 5.0,
        foto_ktm_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
        dibuat_pada: '2024-01-10T09:30:00Z',
      },
      {
        user_id: 'usr-figma-fauzi',
        nama: 'Fauzi Rahman',
        nim: '2401882',
        email: 'fauzi.rahman@upi.edu',
        program_studi: 'Sistem Informasi Kelautan',
        kampus: 'UPI Kampus Cibiru',
        status_verifikasi: 'Menunggu Verifikasi',
        status_akun: 'Menunggu Verifikasi KTM',
        jumlah_transaksi: 0,
        rating: 0.0,
        foto_ktm_url: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=600&q=80',
        dibuat_pada: '2024-11-17T06:00:00Z',
      },
      {
        user_id: 'usr-figma-budi',
        nama: 'Budi Santoso',
        nim: '2104921',
        email: 'budi.santoso@upi.edu',
        program_studi: 'Teknik Komputer',
        kampus: 'UPI Kampus Cibiru',
        status_verifikasi: 'Terverifikasi',
        status_akun: 'Dibekukan Sementara (7 Hari)',
        sanction_reason: 'Pelanggaran Bypass Rekening Bersama Escrow',
        sanction_until: '2024-11-24T23:59:59Z',
        jumlah_transaksi: 5,
        rating: 3.2,
        foto_ktm_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
        dibuat_pada: '2023-09-01T10:00:00Z',
      },
      {
        user_id: 'usr-figma-rian',
        nama: 'Rian Hidayat',
        nim: '2208173',
        email: 'rian.hidayat@upi.edu',
        program_studi: 'Pendidikan Multimedia',
        kampus: 'UPI Kampus Cibiru',
        status_verifikasi: 'Terverifikasi',
        status_akun: 'Terlapor Pelanggaran',
        jumlah_transaksi: 8,
        rating: 4.2,
        foto_ktm_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80',
        dibuat_pada: '2024-02-12T11:00:00Z',
      },
    ];

    // Gabungkan pengguna asli dari database
    const mappedDbUsers = dbUsers.rows.map((u, idx) => ({
      user_id: u.user_id,
      nama: u.nama,
      nim: `220${String(1000 + idx).slice(1)}`,
      email: u.email,
      program_studi: u.peran === 'Penyedia Jasa' ? 'Rekayasa Perangkat Lunak' : 'Pendidikan Multimedia',
      kampus: 'UPI Kampus Cibiru',
      status_verifikasi: u.status_verifikasi,
      status_akun: u.status_verifikasi === 'Terverifikasi' ? 'Aktif' : 'Menunggu Verifikasi KTM',
      jumlah_transaksi: parseInt(u.total_orders || 0, 10),
      rating: 4.8,
      foto_ktm_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
      dibuat_pada: u.dibuat_pada,
    }));

    return [...figmaStudents, ...mappedDbUsers];
  }

  async verifyUser(userId, status, notes) {
    // Coba update ke PostgreSQL jika user_id adalah UUID valid
    try {
      await db.query(
        "UPDATE users SET status_verifikasi = $1 WHERE user_id::text = $2",
        [status === 'Terverifikasi' ? 'Terverifikasi' : 'Ditolak', userId]
      );
      await db.query(
        "INSERT INTO audit_logs (aksi, objek_tipe, objek_id, status_sesudah) VALUES ($1, $2, $3, $4)",
        ['VERIFIKASI_KTM', 'users', userId, `${status}: ${notes || 'Oleh Administrator'}`]
      );
    } catch (_) {
      // Abaikan jika ID adalah mock
    }

    return {
      user_id: userId,
      status_verifikasi: status,
      status_akun: status === 'Terverifikasi' ? 'Aktif' : 'Verifikasi Ditolak',
      catatan: notes,
      diverifikasi_pada: new Date().toISOString(),
    };
  }

  async sanctionUser(userId, sanctionType, notes) {
    try {
      await db.query(
        "INSERT INTO audit_logs (aksi, objek_tipe, objek_id, status_sesudah) VALUES ($1, $2, $3, $4)",
        ['SANKSI_PENGGUNA', 'users', userId, `${sanctionType}: ${notes || ''}`]
      );
    } catch (_) {}

    return {
      user_id: userId,
      sanction: sanctionType,
      status_akun:
        sanctionType === 'Blokir Permanen'
          ? 'Diblokir Permanen'
          : sanctionType === 'Bekukan Akun Sementara (7 Hari)'
          ? 'Dibekukan Sementara (7 Hari)'
          : 'Peringatan Resmi Tercatat',
      catatan: notes,
      tanggal: new Date().toISOString(),
    };
  }

  async getListings() {
    const dbListings = await db.query(
      `SELECT sl.listing_id, sl.judul, sl.deskripsi, sl.harga, sl.status, sl.tipe_penawaran,
              u.nama AS penyedia_nama, u.email AS penyedia_email, s.nama_keterampilan, s.kategori
       FROM service_listings sl
       JOIN users u ON sl.penyedia_id = u.user_id
       JOIN skills s ON sl.skill_id = s.skill_id
       ORDER BY sl.dibuat_pada DESC`
    );

    // Baseline catalog sesuai Figma Screen 4 (178-537)
    const figmaGigs = [
      {
        listing_id: 'srv-101',
        judul: 'Jasa Desain Spanduk & Banner Dies Natalis UPI Cibiru',
        penyedia_nama: 'Salma Nur Oktavia',
        kategori: 'Desain & Grafis',
        harga: 50000,
        rating: 4.9,
        ulasan_count: 18,
        status: 'Aktif',
        indikasi_pelanggaran: null,
      },
      {
        listing_id: 'srv-102',
        judul: 'Jasa Joki Pembuatan Skripsi Kilat & Tugas Kuliah',
        penyedia_nama: 'Akun Anonim (Budi Santoso)',
        kategori: 'Jasa Kampus',
        harga: 150000,
        rating: 2.1,
        ulasan_count: 3,
        status: 'Dilaporkan - Indikasi Joki',
        indikasi_pelanggaran: 'Pelanggaran Integritas Akademik (Anti-Joki Kampus)',
      },
      {
        listing_id: 'srv-103',
        judul: 'Jasa Debugging Backend Node.js Express & PostgreSQL',
        penyedia_nama: 'Arya Fabio Ismail',
        kategori: 'Coding & Web',
        harga: 75000,
        rating: 5.0,
        ulasan_count: 24,
        status: 'Aktif',
        indikasi_pelanggaran: null,
      },
      {
        listing_id: 'srv-104',
        judul: 'Fotografi Wisuda & Dokumentasi Event Kampus',
        penyedia_nama: 'Dimas Arya',
        kategori: 'Multimedia',
        harga: 120000,
        rating: 4.8,
        ulasan_count: 12,
        status: 'Aktif',
        indikasi_pelanggaran: null,
      },
      {
        listing_id: 'srv-105',
        judul: 'Jasa Penulisan Artikel & Terjemahan Abstrak Jurnal',
        penyedia_nama: 'Siti Sarah',
        kategori: 'Penulisan & Terjemahan',
        harga: 40000,
        rating: 4.7,
        ulasan_count: 9,
        status: 'Aktif',
        indikasi_pelanggaran: null,
      },
    ];

    const mappedDbGigs = dbListings.rows.map((g) => ({
      listing_id: g.listing_id,
      judul: g.judul,
      penyedia_nama: g.penyedia_nama,
      kategori: g.kategori || 'Jasa Teknis',
      harga: parseFloat(g.harga) || 0,
      rating: 4.8,
      ulasan_count: 4,
      status: g.status === 'Aktif' ? 'Aktif' : 'Disembunyikan Moderasi',
      indikasi_pelanggaran: null,
    }));

    return [...figmaGigs, ...mappedDbGigs];
  }

  async moderateListing(listingId, action, notes) {
    const statusMap = {
      'Takedown Segera': 'Disembunyikan Moderasi',
      'Hapus Permanen': 'Nonaktif',
      'Peringatan Penyedia': 'Disembunyikan Moderasi',
      'Aktifkan Kembali': 'Aktif',
    };

    const targetStatus = statusMap[action] || 'Disembunyikan Moderasi';

    try {
      await db.query(
        "UPDATE service_listings SET status = $1 WHERE listing_id::text = $2",
        [targetStatus, listingId]
      );
      await db.query(
        "INSERT INTO audit_logs (aksi, objek_tipe, objek_id, status_sesudah) VALUES ($1, $2, $3, $4)",
        ['MODERASI_GIG', 'service_listings', listingId, `${action} -> ${targetStatus}: ${notes || ''}`]
      );
    } catch (_) {}

    return {
      listing_id: listingId,
      action,
      status_terbaru: targetStatus,
      catatan: notes,
      tanggal: new Date().toISOString(),
    };
  }

  async getDisputes() {
    return [
      {
        case_id: 'DS-2024-004',
        judul_layanan: 'Jasa Desain Spanduk Dies Natalis UPI Cibiru',
        nilai_escrow: 50000,
        status_escrow: 'Terkunci di Rekening Penampungan Simulasi',
        status_perkara: 'Sidang Mediasi Terbuka (SLA Overdue 26 Jam)',
        rekomendasi_sistem: 'Split 50:50 (Rp 25.000 Klien / Rp 25.000 Penyedia)',
        klien: {
          nama: 'Dimas Arya',
          email: 'dimas@gmail.com',
          nim: '2201948',
          prodi: 'Pendidikan Multimedia',
          argumen:
            'Keterlambatan pengerjaan 2 hari melebihi batas waktu deadline yang telah disepakati bersama. Acara sudah mendekati hari-H dan spanduk belum selesai, sehingga saya terpaksa memesan alternatif lain. Saya menuntut pengembalian saldo 100%.',
          bukti_nama: 'bukti-chat-whatsapp-deadline.png',
          tuntutan: 'Refund Penuh 100% (Rp 50.000)',
        },
        penyedia: {
          nama: 'Salma Nur Oktavia',
          email: 'salma@gmail.com',
          nim: '2203102',
          prodi: 'Rekayasa Perangkat Lunak',
          argumen:
            'Progres pengerjaan desain banner spanduk sudah mencapai 80% (telah dikirimkan preview draft PDF). Keterlambatan terjadi karena pemesan meminta revisi ukuran dan penambahan 3 logo sponsor di luar brief kesepakatan awal tanpa perpanjangan waktu. Saya menuntut pencairan kompensasi kerja proporsional.',
          bukti_nama: 'draft-spanduk-80percent.pdf',
          progres_kerja: '80%',
          tuntutan: 'Pencairan Proporsional (Kompensasi Kerja)',
        },
      },
    ];
  }

  async resolveDispute(caseId, verdictType, considerationNotes) {
    const verdictMapping = {
      REFUND_100: {
        label: 'Opsi A: Pengembalian Penuh ke Klien (100% - Rp 50.000)',
        pembagian: { klien: 50000, penyedia: 0 },
        status_pesanan: 'Dibatalkan',
        status_escrow: 'Dikembalikan (Simulasi)',
      },
      RELEASE_100: {
        label: 'Opsi B: Pelepasan Penuh ke Penyedia (100% - Rp 50.000)',
        pembagian: { klien: 0, penyedia: 50000 },
        status_pesanan: 'Selesai',
        status_escrow: 'Dilepas (Simulasi)',
      },
      SPLIT_50_50: {
        label: 'Opsi C: Putusan Berimbang / Split 50:50 (Rekomendasi Sistem)',
        pembagian: { klien: 25000, penyedia: 25000 },
        status_pesanan: 'Selesai',
        status_escrow: 'Dilepas (Simulasi)',
      },
    };

    const chosenVerdict = verdictMapping[verdictType] || verdictMapping.SPLIT_50_50;

    try {
      await db.query(
        "INSERT INTO audit_logs (aksi, objek_tipe, objek_id, status_sesudah) VALUES ($1, $2, $3, $4)",
        [
          'PUTUSAN_ARBITRASE_SENGKETA',
          'orders',
          caseId,
          `${chosenVerdict.label} | Pertimbangan: ${considerationNotes || 'Berdasarkan bukti mediasi'}`,
        ]
      );
    } catch (_) {}

    return {
      case_id: caseId,
      verdict_code: verdictType,
      putusan_resmi: chosenVerdict.label,
      pembagian_saldo: chosenVerdict.pembagian,
      status_pesanan: chosenVerdict.status_pesanan,
      status_escrow: chosenVerdict.status_escrow,
      catatan_pertimbangan: considerationNotes,
      dieksekusi_pada: new Date().toISOString(),
      eksekutor: 'Administrator Sidang Arbitrase Kampus',
    };
  }

  async getReports() {
    const dbReports = await db.query(
      `SELECT r.report_id, r.alasan, r.keterangan, r.status_penanganan, r.keputusan, r.dibuat_pada,
              u.nama AS pelapor_nama, u.email AS pelapor_email
       FROM reports r
       JOIN users u ON r.pelapor_id = u.user_id
       ORDER BY r.dibuat_pada DESC`
    );

    const figmaReports = [
      {
        report_id: 'REP-059',
        prioritas: 'Tinggi',
        pelapor_nama: 'Dimas Arya',
        pelapor_nim: '2201948',
        terlapor_nama: 'Rian Hidayat',
        terlapor_nim: '2208173',
        kategori: 'Upaya Transaksi di Luar Sistem (Bypass Rekening Bersama Escrow)',
        deskripsi:
          'Terlapor meminta dan mengajak bertransaksi di luar aplikasi menggunakan transfer langsung rekening bank pribadi via chat WhatsApp dengan alasan menghindari biaya admin dan proses escrow platform SakuSkill.',
        bukti_file: 'bukti-chat-bypass.png',
        status_tiket: 'Menunggu Tindakan',
        dibuat_pada: '2024-11-17T07:15:00Z',
      },
      {
        report_id: 'REP-058',
        prioritas: 'Sedang',
        pelapor_nama: 'Siti Sarah',
        pelapor_nim: '2205119',
        terlapor_nama: 'Budi Santoso',
        terlapor_nim: '2104921',
        kategori: 'Indikasi Joki Tugas Kuliah',
        deskripsi: 'Menawarkan jasa pembuatan makalah komplit yang melanggar kode etik kampus.',
        bukti_file: 'bukti-listing-joki.png',
        status_tiket: 'Dalam Investigasi',
        dibuat_pada: '2024-11-16T14:20:00Z',
      },
      {
        report_id: 'REP-057',
        prioritas: 'Rendah',
        pelapor_nama: 'Ahmad Fauzi',
        pelapor_nim: '2301140',
        terlapor_nama: 'Akun Anonim',
        terlapor_nim: '2409999',
        kategori: 'Spam Pesan Promo',
        deskripsi: 'Mengirim pesan siaran berulang kali di fitur chat transaksi.',
        bukti_file: 'bukti-spam-chat.png',
        status_tiket: 'Selesai',
        dibuat_pada: '2024-11-15T09:10:00Z',
      },
    ];

    const mappedDbReports = dbReports.rows.map((r) => ({
      report_id: r.report_id,
      prioritas: 'Sedang',
      pelapor_nama: r.pelapor_nama,
      pelapor_nim: '2200000',
      terlapor_nama: 'Pihak Terlapor',
      terlapor_nim: '2200001',
      kategori: r.alasan || 'Pengaduan Layanan',
      deskripsi: r.keterangan,
      bukti_file: 'bukti-lampiran.png',
      status_tiket: r.status_penanganan === 'Baru' ? 'Menunggu Tindakan' : r.status_penanganan === 'Ditinjau' ? 'Dalam Investigasi' : 'Selesai',
      dibuat_pada: r.dibuat_pada,
    }));

    return [...figmaReports, ...mappedDbReports];
  }

  async resolveReport(reportId, action, notes) {
    try {
      await db.query(
        "UPDATE reports SET status_penanganan = 'Selesai', keputusan = $1, diselesaikan_pada = NOW() WHERE report_id::text = $2",
        [`${action}: ${notes || ''}`, reportId]
      );
    } catch (_) {}

    return {
      report_id: reportId,
      tindakan_diambil: action,
      catatan_petugas: notes,
      status_tiket: 'Selesai',
      diselesaikan_pada: new Date().toISOString(),
    };
  }

  async getEscrowTransactions() {
    return {
      saldo_penampungan_live: 'Rp 4.250.000',
      badge_status: 'TERKUNCI - SIMULASI ESCROW',
      transaksi: [
        {
          id: 'SK-2024-091',
          jenis: 'Escrow Berbayar',
          pihak: 'Dimas Arya (Klien) -> Salma Nur Oktavia (Penyedia)',
          nominal: 'Rp 50.000',
          status_escrow: 'Ditahan Simulasi (Escrow)',
          status_pesanan: 'Pengerjaan Berjalan',
          tanggal: '17 Nov 2026',
        },
        {
          id: 'SK-2024-058',
          jenis: 'Escrow Berbayar',
          pihak: 'Ahmad Fauzi (Klien) -> Rizkia (Penyedia)',
          nominal: 'Rp 45.000',
          status_escrow: 'Dilepas Simulasi',
          status_pesanan: 'Selesai',
          tanggal: '16 Nov 2026',
        },
        {
          id: 'BTR-2024-012',
          jenis: 'Smart Barter Non-Tunai',
          pihak: 'Salsa (Pihak 1) <-> Rizkia (Pihak 2)',
          nominal: 'Non-Tunai',
          status_escrow: 'Smart Barter Aktif',
          status_pesanan: 'Pengerjaan Bersama',
          tanggal: '17 Nov 2026',
        },
        {
          id: 'DS-2024-004',
          jenis: 'Sengketa Escrow',
          pihak: 'Dimas Arya vs Salma Nur Oktavia',
          nominal: 'Rp 50.000',
          status_escrow: 'Dibekukan (Sengketa)',
          status_pesanan: 'Menunggu Eksekusi 50:50',
          tanggal: '17 Nov 2026',
        },
      ],
    };
  }
}

module.exports = new AdminService();
