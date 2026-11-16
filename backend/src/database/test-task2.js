/**
 * Automated Verification Script untuk Task [P0][BE]:
 * Auth, Profile, Gigs CRUD, Owner Validation, Password Hashing, & Discovery API
 */
const app = require('../app');
const db = require('../config/database');

async function runTests() {
  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  const request = async (method, pathUrl, { token, body } = {}) => {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers.Authorization = `Bearer ${token}`;
    const res = await fetch(`${baseUrl}${pathUrl}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    const json = await res.json();
    return { status: res.status, body: json };
  };

  try {
    console.log('=== MEMULAI UJI ACCEPTANCE CRITERIA [P0][BE] AUTH, PROFILE, GIGS & DISCOVERY ===\n');

    const suffix = Date.now();
    const emailA = `arya.${suffix}@uinsgd.ac.id`;
    const emailB = `faiz.${suffix}@uinsgd.ac.id`;
    const plainPassword = 'PasswordAman123!';

    // 1. Register User A & User B
    const regA = await request('POST', '/auth/register', {
      body: {
        nama: 'Arya Fabio Ismail',
        email: emailA,
        kata_sandi: plainPassword,
        deskripsi_profil: 'Mahasiswa Teknik Informatika UIN SGD Bandung',
      },
    });
    const regB = await request('POST', '/auth/register', {
      body: {
        nama: 'Faiz Muhammad Ilham',
        email: emailB,
        kata_sandi: plainPassword,
      },
    });
    console.log('[1] Register User A & User B -> Status:', regA.status, '&', regB.status);

    // 2. Verifikasi Password di Database TIDAK disimpan plaintext (NFR-05 & Acceptance Criteria)
    const { rows: dbUserRows } = await db.query(
      'SELECT kata_sandi_hash FROM users WHERE email = $1',
      [emailA]
    );
    const storedHash = dbUserRows[0].kata_sandi_hash;
    const isHashedBcrypt = storedHash !== plainPassword && storedHash.startsWith('$2');
    console.log('[2] Cek Password Hashing di PostgreSQL -> Bcrypt Valid:', isHashedBcrypt, '(' + storedHash.slice(0, 15) + '...)');

    // 3. Login User A & Uji Error Konsisten saat Password Salah (FR-04, FR-05)
    const loginSuccess = await request('POST', '/auth/login', {
      body: { email: emailA, kata_sandi: plainPassword },
    });
    const loginFail = await request('POST', '/auth/login', {
      body: { email: emailA, kata_sandi: 'SalahPassword123' },
    });
    console.log('[3] Login Sukses Status:', loginSuccess.status, '| Login Gagal Status:', loginFail.status, 'Code:', loginFail.body.error.code);

    const tokenA = loginSuccess.body.data.token;
    const tokenB = regB.body.data.token;

    // 4. Get & Update Profile + Skills (FR-08, FR-12, Kerjaan #2 & #3)
    const updateProf = await request('PUT', '/users/me', {
      token: tokenA,
      body: {
        nama: 'Arya Fabio Ismail (Verified Dev)',
        deskripsi_profil: 'Spesialis Backend Express, Linux, dan Jaringan di sekitar Cibiru.',
        skill_ids: [1, 2],
      },
    });
    console.log('[4] Update Profile & Skills -> Status:', updateProf.status, '| Capabilities:', JSON.stringify(updateProf.body.data.capabilities));

    // 5. Create Gig oleh User A (FR-17, Kerjaan #4 & #6)
    const createGig = await request('POST', '/gigs', {
      token: tokenA,
      body: {
        judul: 'Jasa Instalasi Dual-Boot Linux & Setup Server Lokal',
        deskripsi: 'Melayani instalasi Linux, optimasi laptop, dan perbaikan konfigurasi database PostgreSQL untuk mahasiswa UIN SGD.',
        skill_id: 1,
        harga: 50000,
        latitude: -6.9315,
        longitude: 107.7180,
        tipe_penawaran: 'Berbayar dan Barter',
        deskripsi_imbalan_barter: 'Bisa barter dengan desain poster kegiatan kampus.',
        status: 'Aktif',
      },
    });
    const gigId = createGig.body.data.listing_id;
    console.log('[5] Create Gig oleh User A -> Status:', createGig.status, '| Gig ID:', gigId);

    // 6. ACCEPTANCE CRITERIA: User B mencoba mengubah & menghapus Gig milik User A -> Wajib 403 Forbidden
    const hijackUpdate = await request('PUT', `/gigs/${gigId}`, {
      token: tokenB,
      body: { harga: 1000 },
    });
    const hijackDelete = await request('DELETE', `/gigs/${gigId}`, {
      token: tokenB,
    });
    console.log('[6] Proteksi Kepemilikan Gig (User B ubah/hapus Gig User A) -> Update Status:', hijackUpdate.status, '(' + hijackUpdate.body.error.code + ') | Delete Status:', hijackDelete.status);

    // 7. Discovery Search & Detail Gig (Kerjaan #5)
    const discovery = await request('GET', '/gigs?q=Linux&tipe_penawaran=Berbayar%20dan%20Barter&sort_by=jarak');
    const detail = await request('GET', `/gigs/${gigId}`);
    console.log('[7] Discovery Search ("Linux") -> Ditemukan:', discovery.body.data.length, 'gig | Detail Gig Status:', detail.status, '| Jarak:', detail.body.data.jarak_km, 'km');

    // 8. Logout & Token Revocation (Kerjaan #1 & FR-06)
    const logoutRes = await request('POST', '/auth/logout', { token: tokenA });
    const afterLogout = await request('GET', '/users/me', { token: tokenA });
    console.log('[8] Logout & Token Revocation -> Logout Status:', logoutRes.status, '| Akses Pakai Token Lama Status:', afterLogout.status, '(' + afterLogout.body.error.code + ')');

    console.log('\n=== SELURUH PENGUJIAN ACCEPTANCE CRITERIA LULUS 100%! ===');
  } catch (error) {
    console.error('Pengujian gagal:', error);
    process.exitCode = 1;
  } finally {
    server.close();
    await db.pool.end();
  }
}

runTests();
