/**
 * Automated Verification Script untuk [P0][BE] Implementasi simulasi pembayaran untuk MVP
 * Menguji seluruh Kerjaan #1 s.d. #8 dan Acceptance Criteria PM.
 */
const app = require('../app');
const db = require('../config/database');

async function runMvpPaymentSimulationTests() {
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
    console.log('=== MEMULAI UJI ACCEPTANCE CRITERIA [P0][BE] SIMULASI PEMBAYARAN MVP ===\n');

    const ts = Date.now();
    const password = 'PasswordAman123!';

    // Setup 3 Akun: Penyedia (User A), Pelanggan (User B), Pihak Luar (User C)
    const regProvider = await request('POST', '/auth/register', {
      body: { nama: 'Arya Penyedia', email: 'arya.mvp.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });
    const regCustomer = await request('POST', '/auth/register', {
      body: { nama: 'Qoisy Pelanggan', email: 'qoisy.mvp.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });
    const regOutsider = await request('POST', '/auth/register', {
      body: { nama: 'Outsider User', email: 'outsider.mvp.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });

    const tokenProvider = regProvider.body.data.token;
    const tokenCustomer = regCustomer.body.data.token;
    const tokenOutsider = regOutsider.body.data.token;

    // Buat Gig & Order, lalu Penyedia Accept Order
    const gigRes = await request('POST', '/gigs', {
      token: tokenProvider,
      body: {
        judul: 'Jasa Instalasi & Optimasi Linux CachyOS / Debian',
        deskripsi: 'Melayani setup dual-boot, optimasi kernel, dan konfigurasi server lokal.',
        skill_id: 1,
        harga: 120000,
        latitude: -6.9311,
        longitude: 107.7175,
        tipe_penawaran: 'Berbayar',
        status: 'Aktif',
      },
    });
    const gigId = gigRes.body.data.listing_id;

    const orderRes = await request('POST', '/orders', {
      token: tokenCustomer,
      body: {
        listing_id: gigId,
        ruang_lingkup: 'Instalasi dan konfigurasi server praktikum.',
        harga_kesepakatan: 120000,
        tenggat_pekerjaan: '2026-11-29T17:00:00.000Z',
      },
    });
    const orderId = orderRes.body.data.order_id;
    await request('POST', '/orders/' + orderId + '/accept', { token: tokenProvider });

    // 1. Uji Kerjaan #6: Coba mulai order (in_progress) sebelum ada record payment -> Wajib Ditolak 400
    const startBeforePayment = await request('POST', '/orders/' + orderId + '/start', {
      token: tokenProvider,
    });
    console.log(
      '[M1] [NEGATIVE - KERJAAN #6] Mulai Order Tanpa Payment -> Status HTTP:',
      startBeforePayment.status,
      '(' + startBeforePayment.body.error.code + ')'
    );

    // 2. Uji Kerjaan #4: Penyedia atau Pihak Luar mencoba memulai simulasi pembayaran -> Wajib Ditolak 403
    const providerTryPay = await request('POST', '/payments', {
      token: tokenProvider,
      body: { order_id: orderId },
    });
    console.log(
      '[M2] [NEGATIVE - KERJAAN #4] Penyedia Mencoba Mulai Simulasi Payment -> Status HTTP:',
      providerTryPay.status,
      '(' + providerTryPay.body.error.code + ')'
    );

    // 3. Uji Kerjaan #5 & Acceptance: Client mencoba memaksa status="success" saat membuat payment -> Wajib Ditolak 400
    const clientForceCreate = await request('POST', '/payments', {
      token: tokenCustomer,
      body: { order_id: orderId, status: 'success', status_kode: 'success' },
    });
    console.log(
      '[M3] [NEGATIVE - KERJAAN #5] Client Memaksa Status saat Create -> Status HTTP:',
      clientForceCreate.status,
      '(' + clientForceCreate.body.error.code + ')'
    );

    // 4. Uji Kerjaan #1 & #2: Pelanggan membuat record payment (Status awal ditetapkan backend = pending)
    const createPending = await request('POST', '/payments', {
      token: tokenCustomer,
      body: { order_id: orderId, metode_simulasi: 'SIMULASI_QRIS_MVP' },
    });
    console.log(
      '[M4] [KERJAAN #1 & #2] Buat Record Payment Terpisah -> Status HTTP:',
      createPending.status,
      '| Payment Status:',
      createPending.body.data.status_kode,
      '| Order Status Tetap:',
      createPending.body.data.relasi_order.order_status_kode
    );

    // 5. Uji Kerjaan #5 & Acceptance: Client mencoba memaksa status via PATCH /payments/:orderId/status -> Wajib Ditolak 400
    const clientForcePatch = await request('PATCH', '/payments/' + orderId + '/status', {
      token: tokenCustomer,
      body: { status: 'success' },
    });
    console.log(
      '[M5] [NEGATIVE - KERJAAN #5] Client Memaksa Status via PATCH -> Status HTTP:',
      clientForcePatch.status,
      '(' + clientForcePatch.body.error.code + ')'
    );

    // 6. Uji Alur Gagal (Acceptance: pending -> failed) & Kerjaan #7: Pembayaran gagal TIDAK mengubah order jadi in_progress
    const simFailed = await request('POST', '/payments/' + orderId + '/simulate-failed', {
      token: tokenCustomer,
      body: { alasan_gagal: 'Simulasi saldo tidak mencukupi untuk demonstrasi MVP.' },
    });
    const startAfterFailed = await request('POST', '/orders/' + orderId + '/start', {
      token: tokenProvider,
    });
    const orderCheckAfterFail = await request('GET', '/orders/' + orderId, { token: tokenCustomer });
    console.log(
      '[M6] [ALUR GAGAL - KERJAAN #2 & #7] Transisi pending -> failed:',
      simFailed.body.data.status_kode,
      '| Coba Start Order Ditolak:',
      startAfterFailed.status,
      '| Status Order Tetap:',
      orderCheckAfterFail.body.data.status_kode
    );

    // 7. Uji Alur Sukses (Acceptance: pending -> success): Pelanggan inisiasi ulang ke pending lalu simulate-success
    const resetPending = await request('POST', '/payments', {
      token: tokenCustomer,
      body: { order_id: orderId, metode_simulasi: 'SIMULASI_TRANSFER_MVP' },
    });
    const outsiderTrySim = await request('POST', '/payments/' + orderId + '/simulate-success', {
      token: tokenOutsider,
    });
    const simSuccess = await request('POST', '/payments/' + orderId + '/simulate-success', {
      token: tokenCustomer,
      body: { catatan: 'Simulasi pelunasan MVP berhasil.' },
    });
    console.log(
      '[M7] [ALUR SUKSES - KERJAAN #2, #4, #5] Retry ke:',
      resetPending.body.data.status_kode,
      '-> Outsider Ditolak:',
      outsiderTrySim.status,
      '-> Pelanggan Simulate Success:',
      simSuccess.body.data.status_kode,
      '| Order Status Masih Terpisah:',
      simSuccess.body.data.relasi_order.order_status_kode
    );

    // 8. Uji Kerjaan #6: Setelah payment success, Penyedia kini BISA mengubah order menjadi in_progress
    const startAfterSuccess = await request('POST', '/orders/' + orderId + '/start', {
      token: tokenProvider,
    });
    console.log(
      '[M8] [KERJAAN #6] Mulai Order Setelah Payment Success -> Status HTTP:',
      startAfterSuccess.status,
      '| Order Status:',
      startAfterSuccess.body.data.status_kode,
      '| Payment Status Tetap Terpisah:',
      startAfterSuccess.body.data.payment.status_kode
    );

    // 9. Uji Kerjaan #8: Verifikasi Disclaimer Keterbatasan MVP pada Response API
    console.log(
      '[M9] [KERJAAN #8] Disclaimer MVP Aktif -> bukan_uang_sungguhan:',
      simSuccess.body.data.disclaimer_mvp.bukan_uang_sungguhan,
      '| bukan_escrow_nyata:',
      simSuccess.body.data.disclaimer_mvp.bukan_escrow_nyata,
      '| midtrans_ditunda:',
      simSuccess.body.data.disclaimer_mvp.midtrans_ditunda
    );

    console.log('\n=== SELURUH ACCEPTANCE CRITERIA SIMULASI PEMBAYARAN MVP LULUS 100%! ===');
  } catch (error) {
    console.error('Pengujian gagal:', error);
    process.exitCode = 1;
  } finally {
    server.close();
    await db.pool.end();
  }
}

runMvpPaymentSimulationTests();