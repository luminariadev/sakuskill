const bcrypt = require('bcryptjs');
const { pool } = require('../config/database');

async function cleanDatabase() {
  const client = await pool.connect();
  try {
    console.log('[CLEAN] Memulai pembersihan data database SakuSkill...');

    // 1. Truncate tabel transaksi operasional yang ada
    await client.query(`
      TRUNCATE TABLE 
        payments,
        order_proposals,
        barter_confirmations,
        barter_agreements,
        orders, 
        reports, 
        reviews, 
        messages, 
        audit_logs,
        service_listings
      CASCADE;
    `);
    console.log('[CLEAN] Seluruh transaksi, pesanan, barter, pembayaran, laporan, ulasan, pesan, dan listing jasa telah dikosongkan.');

    // 2. Bersihkan seluruh pengguna kecuali Administrator
    await client.query("DELETE FROM users WHERE email != 'admin@sakuskill.ac.id';");
    console.log('[CLEAN] Pengguna uji coba berhasil dibersihkan.');

    // 3. Pastikan Akun Administrator tersedia
    const adminCheck = await client.query("SELECT user_id FROM users WHERE email = 'admin@sakuskill.ac.id';");
    if (adminCheck.rows.length === 0) {
      const hash = await bcrypt.hash('rahasia123', 10);
      await client.query(`
        INSERT INTO users (
          nama, 
          email, 
          kata_sandi_hash, 
          peran, 
          status_verifikasi, 
          deskripsi_profil
        ) VALUES (
          'Super Admin SakuSkill', 
          'admin@sakuskill.ac.id', 
          $1, 
          'Administrator', 
          'Terverifikasi', 
          'Administrator Operasional & Mediasi SakuSkill UPI Cibiru'
        );
      `, [hash]);
      console.log('[CLEAN] Akun default Administrator berhasil dibuat (admin@sakuskill.ac.id / rahasia123).');
    } else {
      console.log('[CLEAN] Akun Administrator dipertahankan (admin@sakuskill.ac.id).');
    }

    // 4. Pastikan Master Kategori Keterampilan tersedia
    await client.query(`
      INSERT INTO skills (nama_keterampilan, kategori) VALUES
        ('Instalasi OS & Perbaikan Laptop', 'Jasa Teknis'),
        ('Debugging & Pembuatan Web Sederhana', 'Jasa Teknis'),
        ('Desain UI/UX & Grafis Poster', 'Desain'),
        ('Fotografi Wisuda & Kegiatan Kampus', 'Fotografi'),
        ('Bimbingan Belajar Pemrograman Dasar', 'Bimbingan Belajar'),
        ('Video Editing & Motion Graphics', 'Multimedia'),
        ('Penerjemahan Dokumen & Proofreading', 'Penulisan')
      ON CONFLICT (nama_keterampilan) DO NOTHING;
    `);
    console.log('[CLEAN] Master kategori keterampilan siap digunakan.');

    console.log('\n[CLEAN] SUKSES! Database SakuSkill kini dalam kondisi BERSIH (Clean Slate) siap untuk demo.');
  } catch (error) {
    console.error('[CLEAN] Gagal membersihkan database:', error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

cleanDatabase();
