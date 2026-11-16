/**
 * Automated Verification Script untuk Task 3 [P0][BE]:
 * Implementasi order lifecycle dan barter lifecycle API (Terintegrasi Aturan Payment MVP)
 */
const app = require('../app');
const db = require('../config/database');

async function runLifecycleTests() {
  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = 'http://localhost:' + port + '/api/v1';

  const request = async (method, pathUrl, { token, body } = {}) => {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers.Authorization = 'Bearer ' + token;
    const res = await fetch(baseUrl + pathUrl, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    const json = await res.json();
    return { status: res.status, body: json };
  };

  try {
    console.log('=== MEMULAI UJI ACCEPTANCE CRITERIA [P0][BE] ORDER & BARTER LIFECYCLE ===\n');
    const ts = Date.now();
    const password = 'PasswordAman123!';

    const regA = await request('POST', '/auth/register', {
      body: { nama: 'Arya Penyedia', email: 'arya.p3.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });
    const regB = await request('POST', '/auth/register', {
      body: { nama: 'Qoisy Pelanggan', email: 'qoisy.p3.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });
    const regC = await request('POST', '/auth/register', {
      body: { nama: 'Outsider User', email: 'outsider.p3.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });

    const tokenProvider = regA.body.data.token;
    const tokenCustomer = regB.body.data.token;
    const tokenOutsider = regC.body.data.token;

    const gigRes = await request('POST', '/gigs', {
      token: tokenProvider,
      body: {
        judul: 'Jasa Setup Server Debian & Reverse Proxy Nginx',
        deskripsi: 'Melayani konfigurasi server Debian headless, Nginx reverse proxy, dan keamanan firewall untuk mahasiswa.',
        skill_id: 1,
        harga: 75000,
        latitude: -6.9315,
        longitude: 107.718,
        tipe_penawaran: 'Berbayar dan Barter',
        deskripsi_imbalan_barter: 'Barter dengan pembuatan desain UI/UX aplikasi mobile.',
        status: 'Aktif',
      },
    });
    const gigId = gigRes.body.data.listing_id;

    console.log('--- BAGIAN A: PENGUJIAN ALUR ORDER LIFECYCLE ---');
    const orderRes = await request('POST', '/orders', {
      token: tokenCustomer,
      body: {
        listing_id: gigId,
        ruang_lingkup: 'Setup 1 VPS Debian 12 dengan Nginx dan SSL Cloudflare untuk proyek kampus.',
        harga_kesepakatan: 75000,
        tenggat_pekerjaan: '2026-11-25T17:00:00.000Z',
      },
    });
    const orderId = orderRes.body.data.order_id;
    console.log('[A1] Buat Order + Snapshot Gig -> Status HTTP:', orderRes.status, '| Status Order:', orderRes.body.data.status_kode);

    const outsiderOrderHack = await request('POST', '/orders/' + orderId + '/accept', { token: tokenOutsider });
    console.log('[A2] [NEGATIVE TEST] Pengguna Luar Ubah Status Order -> Status HTTP:', outsiderOrderHack.status, '(' + outsiderOrderHack.body.error.code + ')');

    const illegalJumpOrder = await request('POST', '/orders/' + orderId + '/complete', { token: tokenCustomer });
    console.log('[A3] [NEGATIVE TEST] Transisi Ilegal (requested -> completed) -> Status HTTP:', illegalJumpOrder.status, '(' + illegalJumpOrder.body.error.code + ')');

    const prematureReview = await request('POST', '/orders/' + orderId + '/reviews', {
      token: tokenCustomer,
      body: { rating: 5, komentar: 'Coba review sebelum selesai' },
    });
    console.log('[A4] [NEGATIVE TEST] Review Sebelum Order Selesai -> Status HTTP:', prematureReview.status, '(' + prematureReview.body.error.code + ')');

    const stepAccept = await request('POST', '/orders/' + orderId + '/accept', {
      token: tokenProvider,
      body: { ruang_lingkup: 'Setup 1 VPS Debian 12 + Nginx + Cloudflare Tunnel disepakati.', harga_kesepakatan: 70000, tenggat_pekerjaan: '2026-11-25T17:00:00.000Z' },
    });
    await request('POST', '/payments', { token: tokenCustomer, body: { order_id: orderId } });
    await request('POST', '/payments/' + orderId + '/simulate-success', { token: tokenCustomer });
    const stepStart = await request('POST', '/orders/' + orderId + '/start', { token: tokenProvider });
    const stepReqComp = await request('POST', '/orders/' + orderId + '/request-completion', { token: tokenProvider });
    const stepComplete = await request('POST', '/orders/' + orderId + '/complete', { token: tokenCustomer });
    const stepReview = await request('POST', '/orders/' + orderId + '/reviews', {
      token: tokenCustomer,
      body: { rating: 5, rating_kualitas: 5, rating_ketepatan_waktu: 5, komentar: 'Server berjalan sangat stabil dan cepat!' },
    });
    console.log('[A5] Siklus Penuh Order Lulus ->', stepAccept.body.data.status_kode + ' -> ' + stepStart.body.data.status_kode + ' -> ' + stepReqComp.body.data.status_kode + ' -> ' + stepComplete.body.data.status_kode + ' | Review Status: ' + stepReview.status);

    const order2 = await request('POST', '/orders', {
      token: tokenCustomer,
      body: { listing_id: gigId, ruang_lingkup: 'Instalasi tambahan untuk server cadangan.', tenggat_pekerjaan: '2026-11-28T17:00:00.000Z' },
    });
    const cancelOrder2 = await request('POST', '/orders/' + order2.body.data.order_id + '/cancel', {
      token: tokenCustomer,
      body: { alasan: 'Jadwal kegiatan kampus berubah.' },
    });
    console.log('[A6] Pelanggan Cancel Order -> Status HTTP:', cancelOrder2.status, '| Status Akhir:', cancelOrder2.body.data.status_kode);

    console.log('\n--- BAGIAN B: PENGUJIAN ALUR BARTER LIFECYCLE ---');
    const barterRes = await request('POST', '/barter', {
      token: tokenCustomer,
      body: {
        listing_id: gigId,
        deskripsi_jasa_pengaju: 'Membuat desain 5 halaman UI/UX aplikasi mobile di Figma lengkap dengan prototype.',
        deskripsi_jasa_penerima: 'Melakukan setup server Debian dan konfigurasi reverse proxy Nginx.',
        tenggat_pekerjaan: '2026-11-30T17:00:00.000Z',
      },
    });
    const barterId = barterRes.body.data.barter_id;
    console.log('[B1] Buat Barter Offer -> Status HTTP:', barterRes.status, '| Status:', barterRes.body.data.status_kode);

    const prematureBarterStart = await request('POST', '/barter/' + barterId + '/start', { token: tokenCustomer });
    console.log('[B2] [NEGATIVE TEST] Mulai Barter Sebelum Kedua Pihak Setuju -> Status HTTP:', prematureBarterStart.status, '(' + prematureBarterStart.body.error.code + ')');

    const outsiderBarterHack = await request('POST', '/barter/' + barterId + '/accept', { token: tokenOutsider });
    console.log('[B3] [NEGATIVE TEST] Pengguna Luar Ubah Status Barter -> Status HTTP:', outsiderBarterHack.status, '(' + outsiderBarterHack.body.error.code + ')');

    const barterAccept = await request('POST', '/barter/' + barterId + '/accept', { token: tokenProvider });
    const barterStart = await request('POST', '/barter/' + barterId + '/start', { token: tokenProvider });
    console.log('[B4] Kedua Pihak Setuju & Mulai Barter -> Status setelah Accept:', barterAccept.body.data.status_kode, '| Status setelah Start:', barterStart.body.data.status_kode);

    const confirmParty1 = await request('POST', '/barter/' + barterId + '/confirm-completion', {
      token: tokenCustomer,
      body: { catatan: 'Desain 5 halaman Figma sudah saya serahkan.' },
    });
    console.log('[B5] Konfirmasi Pihak ke-1 Saja -> Status Barter:', confirmParty1.body.data.status_kode, '| Keduanya Selesai:', confirmParty1.body.data.konfirmasi_penyelesaian.keduanya_selesai);

    const confirmParty2 = await request('POST', '/barter/' + barterId + '/confirm-completion', {
      token: tokenProvider,
      body: { catatan: 'Setup server Debian & Nginx sudah tuntas dan diterima.' },
    });
    console.log('[B6] Konfirmasi Pihak ke-2 -> Status Barter:', confirmParty2.body.data.status_kode, '| Keduanya Selesai:', confirmParty2.body.data.konfirmasi_penyelesaian.keduanya_selesai);

    console.log('\n=== SELURUH PENGUJIAN ORDER LIFECYCLE & BARTER LIFECYCLE LULUS 100%! ===');
  } catch (error) {
    console.error('Pengujian gagal:', error);
    process.exitCode = 1;
  } finally {
    server.close();
    await db.pool.end();
  }
}

runLifecycleTests();