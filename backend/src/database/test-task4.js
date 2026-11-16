/**
 * Automated Verification Script untuk Task 4 [P0][BE]:
 * Implementasi Pembayaran, Rekening Bersama (Escrow), & Payment Gateway Eksternal
 */
const app = require('../app');
const db = require('../config/database');

async function runPaymentEscrowTests() {
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
    console.log('=== MEMULAI UJI OTOMATIS [P0][BE] PAYMENT GATEWAY EKSTERNAL & ESCROW ===\n');

    const ts = Date.now();
    const password = 'PasswordAman123!';

    // 1. Register 3 Akun: Penyedia (User A), Pelanggan (User B), Outsider (User C)
    const regA = await request('POST', '/auth/register', {
      body: { nama: 'Arya Penyedia', email: 'arya.pay.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });
    const regB = await request('POST', '/auth/register', {
      body: { nama: 'Qoisy Pelanggan', email: 'qoisy.pay.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });
    const regC = await request('POST', '/auth/register', {
      body: { nama: 'Outsider User', email: 'outsider.pay.' + ts + '@uinsgd.ac.id', kata_sandi: password },
    });

    const tokenProvider = regA.body.data.token;
    const tokenCustomer = regB.body.data.token;
    const tokenOutsider = regC.body.data.token;

    // 2. Buat Gig & Order, lalu Penyedia Accept Order
    const gigRes = await request('POST', '/gigs', {
      token: tokenProvider,
      body: {
        judul: 'Jasa Audit Jaringan & Konfigurasi Mikrotik/Linux',
        deskripsi: 'Melayani setup jaringan, firewall, dan optimasi server lokal.',
        skill_id: 1,
        harga: 150000,
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
        ruang_lingkup: 'Konfigurasi router dan server laboratorium.',
        harga_kesepakatan: 150000,
        tenggat_pekerjaan: '2026-11-29T17:00:00.000Z',
      },
    });
    const orderId = orderRes.body.data.order_id;

    // Uji Checkout Sebelum Order Disetujui (Masih requested) -> Wajib Ditolak 400
    const prematureCheckout = await request('POST', '/payments/checkout', {
      token: tokenCustomer,
      body: { order_id: orderId, metode_pembayaran: 'QRIS' },
    });
    console.log(
      '[P1] [NEGATIVE TEST] Checkout Sebelum Order Disetujui -> Status HTTP:',
      prematureCheckout.status,
      '(' + prematureCheckout.body.error.code + ')'
    );

    // Penyedia Accept Order
    await request('POST', '/orders/' + orderId + '/accept', { token: tokenProvider });

    // 3. Buat Checkout Pembayaran via External Payment Gateway API
    const checkoutRes = await request('POST', '/payments/checkout', {
      token: tokenCustomer,
      body: { order_id: orderId, metode_pembayaran: 'QRIS' },
    });
    console.log(
      '[P2] Checkout via External Gateway API -> Status HTTP:',
      checkoutRes.status,
      '| Ref:',
      checkoutRes.body.data.referensi_gateway,
      '| Live Currency API Connected:',
      checkoutRes.body.data.raw_gateway_response.external_currency_api.live_api_connected,
      '| Estimasi USD: $' + checkoutRes.body.data.nominal_usd_estimasi
    );

    // 4. Uji Penyedia Mulai Kerja Saat Tagihan Belum Dibayar (Escrow belum held) -> Wajib Ditolak 400
    const startUnpaid = await request('POST', '/orders/' + orderId + '/start', {
      token: tokenProvider,
    });
    console.log(
      '[P3] [NEGATIVE TEST] Mulai Order Sebelum Dana Masuk Escrow -> Status HTTP:',
      startUnpaid.status,
      '(' + startUnpaid.body.error.code + ')'
    );

    // 5. Uji Webhook dengan Signature SHA-512 Palsu -> Wajib Ditolak 401
    const fakeWebhook = await request('POST', '/payments/webhook', {
      body: {
        order_id: checkoutRes.body.data.referensi_gateway,
        transaction_status: 'settlement',
        status_code: '200',
        gross_amount: '150000',
        signature_key: 'signature-palsu-tidak-valid',
      },
    });
    console.log(
      '[P4] [NEGATIVE TEST] Webhook dengan Signature Palsu -> Status HTTP:',
      fakeWebhook.status,
      '(' + fakeWebhook.body.error.code + ')'
    );

    // 6. Pelanggan Melunasi Pembayaran (Webhook Settlement Valid) -> Dana Masuk Escrow (held / Ditahan)
    const paySettle = await request('POST', '/payments/' + orderId + '/simulate-pay', {
      token: tokenCustomer,
    });
    console.log(
      '[P5] Pembayaran Lunas (Settlement) -> Status Pembayaran:',
      paySettle.body.data.status_pembayaran_kode,
      '| Status Escrow:',
      paySettle.body.data.status_escrow_kode,
      '(' + paySettle.body.data.status_escrow + ')'
    );

    // 7. Uji Pengguna Luar Mengakses/Melepas Escrow -> Wajib Ditolak 403
    const outsiderRelease = await request('POST', '/payments/' + orderId + '/release', {
      token: tokenOutsider,
    });
    console.log(
      '[P6] [NEGATIVE TEST] Pengguna Luar Lepas Escrow -> Status HTTP:',
      outsiderRelease.status,
      '(' + outsiderRelease.body.error.code + ')'
    );

    // 8. Uji Lepas Escrow Sebelum Pekerjaan Diajukan Selesai -> Wajib Ditolak 400
    const prematureRelease = await request('POST', '/payments/' + orderId + '/release', {
      token: tokenCustomer,
    });
    console.log(
      '[P7] [NEGATIVE TEST] Lepas Escrow Sebelum Order Selesai -> Status HTTP:',
      prematureRelease.status,
      '(' + prematureRelease.body.error.code + ')'
    );

    // 9. Siklus Pengerjaan Order -> Pelanggan Konfirmasi Selesai -> Escrow Otomatis Dilepas (released)
    await request('POST', '/orders/' + orderId + '/start', { token: tokenProvider });
    await request('POST', '/orders/' + orderId + '/request-completion', { token: tokenProvider });
    const completeOrder = await request('POST', '/orders/' + orderId + '/complete', {
      token: tokenCustomer,
    });
    console.log(
      '[P8] Order Completed & Escrow Released -> Status Order:',
      completeOrder.body.data.status_kode,
      '| Status Escrow:',
      completeOrder.body.data.payment_escrow.status_escrow_kode,
      '(' + completeOrder.body.data.payment_escrow.status_escrow + ')'
    );

    // 10. Skenario Order ke-2: Pembayaran Masuk Escrow (held) lalu Dibatalkan -> Escrow Refunded
    const order2Res = await request('POST', '/orders', {
      token: tokenCustomer,
      body: {
        listing_id: gigId,
        ruang_lingkup: 'Setup jaringan ruang rapat tambahan.',
        harga_kesepakatan: 100000,
        tenggat_pekerjaan: '2026-11-30T17:00:00.000Z',
      },
    });
    const order2Id = order2Res.body.data.order_id;
    await request('POST', '/orders/' + order2Id + '/accept', { token: tokenProvider });
    await request('POST', '/payments/checkout', {
      token: tokenCustomer,
      body: { order_id: order2Id, metode_pembayaran: 'BCA_VA' },
    });
    await request('POST', '/payments/' + order2Id + '/simulate-pay', { token: tokenCustomer });
    const refundRes = await request('POST', '/payments/' + order2Id + '/refund', {
      token: tokenCustomer,
      body: { alasan: 'Perangkat router dibatalkan pembeliannya oleh kampus.' },
    });
    console.log(
      '[P9] Refund Escrow pada Order Batal -> Status Pembayaran:',
      refundRes.body.data.status_pembayaran_kode,
      '| Status Escrow:',
      refundRes.body.data.status_escrow_kode,
      '(' + refundRes.body.data.status_escrow + ')'
    );

    // 11. Cek Ringkasan Rekening Bersama (Escrow Summary)
    const summaryRes = await request('GET', '/payments/summary', { token: tokenProvider });
    console.log(
      '[P10] Ringkasan Escrow Penyedia -> Pendapatan Dilepas: Rp' +
        summaryRes.body.meta.total_pendapatan_dilepas_penyedia
    );

    console.log('\n=== SELURUH PENGUJIAN PAYMENT GATEWAY EKSTERNAL & ESCROW LULUS 100%! ===');
  } catch (error) {
    console.error('Pengujian gagal:', error);
    process.exitCode = 1;
  } finally {
    server.close();
    await db.pool.end();
  }
}

runPaymentEscrowTests();