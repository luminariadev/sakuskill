const paymentsRepository = require('./payments.repository');
const ordersRepository = require('../orders/orders.repository');
const gatewayService = require('./gateway.service');
const AppError = require('../../utils/AppError');

class PaymentsService {
  assertParticipant(paymentOrOrder, user) {
    const isAdmin = user.peran === 'Administrator';
    const isCustomer = paymentOrOrder.pelanggan_id === user.user_id;
    const isProvider = paymentOrOrder.penyedia_id === user.user_id;
    if (!isCustomer && !isProvider && !isAdmin) {
      throw new AppError(
        'Akses ditolak. Pengguna di luar transaksi tidak diizinkan mengakses atau mengubah pembayaran/escrow ini.',
        403,
        'FORBIDDEN_NOT_PARTICIPANT'
      );
    }
    return { isCustomer, isProvider, isAdmin };
  }

  /**
   * 1. Checkout Order & Panggil API Payment Gateway Eksternal
   */
  async createCheckout(user, { order_id: orderId, metode_pembayaran: metodePembayaran }) {
    const order = await paymentsRepository.findOrderWithCustomer(orderId);
    if (!order) {
      throw new AppError('Data order tidak ditemukan.', 404, 'ORDER_NOT_FOUND');
    }

    const { isCustomer } = this.assertParticipant(order, user);
    if (!isCustomer) {
      throw new AppError(
        'Hanya Pelanggan pada order ini yang dapat membuat tagihan pembayaran (checkout).',
        403,
        'FORBIDDEN_ROLE_ACTION'
      );
    }

    if (!['accepted', 'in_progress'].includes(order.status_kode)) {
      throw new AppError(
        `Pembayaran hanya dapat dibuat setelah order disetujui penyedia ('accepted'). Status order saat ini: '${order.status_kode}'.`,
        400,
        'INVALID_ORDER_STATE_FOR_PAYMENT'
      );
    }

    const existing = await paymentsRepository.findByOrderId(orderId);
    if (existing && ['settlement'].includes(existing.status_pembayaran_kode)) {
      throw new AppError(
        'Order ini sudah dibayar dan dana sudah ditahan di rekening bersama (Escrow).',
        409,
        'PAYMENT_ALREADY_SETTLED'
      );
    }

    // Panggil API Payment Gateway Eksternal (Midtrans Snap / Open ExchangeRate + GoQR API)
    const gatewayResult = await gatewayService.createExternalCharge({
      order,
      customer: { nama: order.nama_pelanggan, email: order.email_pelanggan },
      metodePembayaran,
    });

    const saved = await paymentsRepository.upsertCheckoutPayment({
      orderId: order.order_id,
      pelangganId: order.pelanggan_id,
      penyediaId: order.penyedia_id,
      metodePembayaran,
      nominal: order.harga_kesepakatan,
      gatewayProvider: gatewayResult.gatewayProvider,
      referensiGateway: gatewayResult.referensiGateway,
      snapToken: gatewayResult.snapToken,
      paymentUrl: gatewayResult.paymentUrl,
      qrCodeUrl: gatewayResult.qrCodeUrl,
      vaNumber: gatewayResult.vaNumber,
      kursUsdReferensi: gatewayResult.kursUsdReferensi,
      nominalUsdEstimasi: gatewayResult.nominalUsdEstimasi,
      rawGatewayResponse: gatewayResult.rawGatewayResponse,
    });

    await paymentsRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'CREATE_PAYMENT_CHECKOUT',
      objekId: saved.payment_id,
      statusSebelum: existing ? existing.status_escrow_kode : null,
      statusSesudah: 'pending/none',
    });

    return saved;
  }

  /**
   * 2. Webhook Notification Handler dari Payment Gateway (Midtrans Standard)
   */
  async handleGatewayWebhook(payload) {
    const payment = await paymentsRepository.findByGatewayRefOrOrderId(payload.order_id);
    if (!payment) {
      throw new AppError(
        `Data pembayaran untuk referensi '${payload.order_id}' tidak ditemukan.`,
        404,
        'PAYMENT_NOT_FOUND'
      );
    }

    // Verifikasi Signature SHA-512 apabila dikirim oleh Payment Gateway
    if (payload.signature_key) {
      const isValid = gatewayService.verifySignature(
        payload.order_id,
        payload.status_code,
        payload.gross_amount,
        payload.signature_key
      );
      if (!isValid) {
        throw new AppError(
          'Signature key webhook payment gateway tidak valid (SHA-512 mismatch).',
          401,
          'INVALID_WEBHOOK_SIGNATURE'
        );
      }
    }

    const txStatus = payload.transaction_status;

    if (txStatus === 'settlement' || txStatus === 'capture') {
      if (payment.status_escrow_kode === 'released') {
        return payment;
      }
      const updated = await paymentsRepository.updatePaymentAndEscrowState(payment.order_id, {
        statusPembayaran: 'Berhasil',
        statusPembayaranKode: 'settlement',
        statusEscrow: 'Ditahan',
        statusEscrowKode: 'held',
        catatanEscrow: 'Dana pembayaran pelanggan telah diterima dari Payment Gateway dan ditahan di Rekening Bersama (Escrow) SakuSkill.',
        markPaidNow: true,
      });

      await paymentsRepository.writeAuditLog({
        aktorId: payment.pelanggan_id,
        aksi: 'WEBHOOK_PAYMENT_SETTLEMENT_ESCROW_HELD',
        objekId: payment.payment_id,
        statusSebelum: payment.status_escrow_kode,
        statusSesudah: 'held',
      });

      return updated;
    }

    if (['cancel', 'deny', 'failure'].includes(txStatus)) {
      return paymentsRepository.updatePaymentAndEscrowState(payment.order_id, {
        statusPembayaran: 'Gagal',
        statusPembayaranKode: 'failed',
        statusEscrow: 'Belum Aktif',
        statusEscrowKode: 'none',
        catatanEscrow: 'Pembayaran dibatalkan atau ditolak oleh Payment Gateway.',
      });
    }

    if (txStatus === 'expire') {
      return paymentsRepository.updatePaymentAndEscrowState(payment.order_id, {
        statusPembayaran: 'Kedaluwarsa',
        statusPembayaranKode: 'expired',
        statusEscrow: 'Belum Aktif',
        statusEscrowKode: 'none',
        catatanEscrow: 'Batas waktu pembayaran di Payment Gateway telah berakhir.',
      });
    }

    return payment;
  }

  /**
   * 3. Simulasi Pembayaran Berhasil (Untuk Pengujian Tanpa Browser Midtrans)
   */
  async simulatePaymentSettlement(orderId, user) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError(
        'Tagihan pembayaran belum dibuat untuk order ini. Panggil POST /api/v1/payments/checkout terlebih dahulu.',
        404,
        'PAYMENT_NOT_FOUND'
      );
    }

    this.assertParticipant(payment, user);

    if (payment.status_pembayaran_kode !== 'pending') {
      throw new AppError(
        `Transisi pembayaran ilegal: pembayaran sudah berstatus '${payment.status_pembayaran_kode}'.`,
        400,
        'INVALID_PAYMENT_TRANSITION'
      );
    }

    const grossAmount = String(Math.round(Number(payment.nominal)));
    const signatureKey = gatewayService.generateSignature(
      payment.referensi_gateway,
      '200',
      grossAmount
    );

    return this.handleGatewayWebhook({
      order_id: payment.referensi_gateway,
      transaction_status: 'settlement',
      status_code: '200',
      gross_amount: grossAmount,
      signature_key: signatureKey,
    });
  }

  /**
   * 4. Pelepasan Dana Escrow (Release) ke Penyedia Jasa
   * Hanya sah apabila dana berstatus held (Ditahan) dan Order minimal completion_requested / completed
   */
  async releaseEscrow(orderId, user, payload = {}) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError('Data pembayaran/escrow tidak ditemukan untuk order ini.', 404, 'PAYMENT_NOT_FOUND');
    }

    const { isCustomer, isAdmin } = this.assertParticipant(payment, user);
    if (!isCustomer && !isAdmin) {
      throw new AppError(
        'Hanya Pelanggan atau Administrator yang dapat melepas dana Escrow ke Penyedia Jasa.',
        403,
        'FORBIDDEN_ROLE_ACTION'
      );
    }

    if (payment.status_escrow_kode !== 'held') {
      throw new AppError(
        `Transisi escrow ilegal: dana hanya dapat dilepas (released) jika berstatus 'held' (Ditahan). Status saat ini: '${payment.status_escrow_kode}'.`,
        400,
        'INVALID_ESCROW_TRANSITION'
      );
    }

    if (!['completion_requested', 'completed'].includes(payment.status_order_kode)) {
      throw new AppError(
        `Transisi escrow ilegal: dana tidak dapat dilepas karena pekerjaan order belum diajukan selesai ('completion_requested' / 'completed'). Status order saat ini: '${payment.status_order_kode}'.`,
        400,
        'ORDER_NOT_READY_FOR_RELEASE'
      );
    }

    // Jika order masih completion_requested, otomatis tandai order sebagai completed
    if (payment.status_order_kode === 'completion_requested') {
      await ordersRepository.updateOrderState(orderId, {
        statusPesanan: 'Selesai',
        statusKode: 'completed',
        markCompletedNow: true,
      });
    }

    const updated = await paymentsRepository.updatePaymentAndEscrowState(orderId, {
      statusPembayaran: 'Berhasil',
      statusPembayaranKode: 'settlement',
      statusEscrow: 'Dilepas',
      statusEscrowKode: 'released',
      catatanEscrow:
        payload.catatan ||
        'Pelanggan telah mengonfirmasi pekerjaan selesai. Dana Escrow resmi dilepas (dicairkan) ke Penyedia Jasa.',
      markReleasedNow: true,
    });

    await paymentsRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'RELEASE_ESCROW_TO_PROVIDER',
      objekId: payment.payment_id,
      statusSebelum: 'held',
      statusSesudah: 'released',
    });

    return updated;
  }

  /**
   * 5. Pengembalian Dana Escrow (Refund) ke Pelanggan
   */
  async refundEscrow(orderId, user, payload = {}) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError('Data pembayaran/escrow tidak ditemukan untuk order ini.', 404, 'PAYMENT_NOT_FOUND');
    }

    const { isCustomer, isProvider, isAdmin } = this.assertParticipant(payment, user);

    if (payment.status_escrow_kode !== 'held') {
      throw new AppError(
        `Transisi escrow ilegal: refund hanya dapat dilakukan saat dana berstatus 'held' (Ditahan). Status saat ini: '${payment.status_escrow_kode}'.`,
        400,
        'INVALID_ESCROW_TRANSITION'
      );
    }

    if (payment.status_order_kode === 'completed') {
      throw new AppError(
        'Order yang sudah selesai (completed) tidak dapat di-refund.',
        400,
        'INVALID_ESCROW_TRANSITION'
      );
    }

    if (isCustomer && !['requested', 'negotiating', 'accepted', 'cancelled'].includes(payment.status_order_kode)) {
      throw new AppError(
        'Pelanggan tidak dapat melakukan refund sepihak ketika pekerjaan sudah sedang dikerjakan (in_progress). Mintalah persetujuan Penyedia atau Admin.',
        403,
        'FORBIDDEN_ROLE_ACTION'
      );
    }

    if (!isCustomer && !isProvider && !isAdmin) {
      throw new AppError('Akses ditolak.', 403, 'FORBIDDEN_NOT_PARTICIPANT');
    }

    // Pastikan status order juga ditandai cancelled / Dibatalkan jika belum
    if (payment.status_order_kode !== 'cancelled') {
      await ordersRepository.updateOrderState(orderId, {
        statusPesanan: 'Dibatalkan',
        statusKode: 'cancelled',
        alasanPembatalan: payload.alasan || payload.catatan || 'Order dibatalkan dan dana Escrow dikembalikan (refund).',
      });
    }

    const updated = await paymentsRepository.updatePaymentAndEscrowState(orderId, {
      statusPembayaran: 'Dikembalikan',
      statusPembayaranKode: 'refunded',
      statusEscrow: 'Dikembalikan',
      statusEscrowKode: 'refunded',
      catatanEscrow:
        payload.alasan ||
        payload.catatan ||
        'Dana Escrow telah dikembalikan (refunded) sepenuhnya kepada Pelanggan.',
      markRefundedNow: true,
    });

    await paymentsRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'REFUND_ESCROW_TO_CUSTOMER',
      objekId: payment.payment_id,
      statusSebelum: 'held',
      statusSesudah: 'refunded',
    });

    return updated;
  }

  async getPaymentByOrder(orderId, user) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError('Data pembayaran/escrow tidak ditemukan untuk order ini.', 404, 'PAYMENT_NOT_FOUND');
    }
    this.assertParticipant(payment, user);
    return payment;
  }

  async listMyPayments(userId) {
    const items = await paymentsRepository.listUserPayments(userId);
    const summary = await paymentsRepository.getEscrowSummary(userId);
    return { summary, items };
  }
}

module.exports = new PaymentsService();