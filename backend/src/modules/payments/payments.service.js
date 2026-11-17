const paymentsRepository = require('./payments.repository');
const AppError = require('../../utils/AppError');

const PAYMENT_STATUS_LABEL = {
  pending: 'Menunggu',
  success: 'Berhasil',
  failed: 'Gagal',
};

class PaymentsService {
  assertParticipant(record, user) {
    const isAdmin = user.peran === 'Administrator';
    const isCustomer = record.pelanggan_id === user.user_id;
    const isProvider = record.penyedia_id === user.user_id;
    if (!isCustomer && !isProvider && !isAdmin) {
      throw new AppError(
        'Akses ditolak. Pengguna di luar transaksi tidak diizinkan mengakses data pembayaran ini.',
        403,
        'FORBIDDEN_NOT_PARTICIPANT'
      );
    }
    return { isCustomer, isProvider, isAdmin };
  }

  /**
   * Kerjaan #4: Validasi bahwa HANYA pelanggan terkait yang dapat memulai simulasi pembayaran.
   */
  assertOnlyCustomer(record, user) {
    this.assertParticipant(record, user);
    if (record.pelanggan_id !== user.user_id) {
      throw new AppError(
        'Akses ditolak. Hanya Pelanggan terkait pada order ini yang dapat memulai atau menjalankan simulasi pembayaran.',
        403,
        'FORBIDDEN_ONLY_CUSTOMER'
      );
    }
  }

  /**
   * Kerjaan #1, #2, #4, #5: Buat record payment terpisah dengan status awal pending yang ditetapkan backend.
   */
  async initiatePayment(user, { order_id: orderId, metode_simulasi: metodeSimulasi, catatan }) {
    const order = await paymentsRepository.findOrderById(orderId);
    if (!order) {
      throw new AppError('Data order tidak ditemukan.', 404, 'ORDER_NOT_FOUND');
    }

    // Kerjaan #4: Hanya pelanggan terkait yang boleh memulai pembayaran
    this.assertOnlyCustomer(order, user);

    if (order.status_kode !== 'accepted') {
      throw new AppError(
        `Simulasi pembayaran hanya dapat dimulai ketika order berstatus 'accepted' (Disepakati). Status order saat ini: '${order.status_kode}'.`,
        400,
        'INVALID_ORDER_STATE_FOR_PAYMENT'
      );
    }

    const existing = await paymentsRepository.findByOrderId(orderId);
    if (existing && existing.status_kode === 'success') {
      throw new AppError(
        'Pembayaran untuk order ini sudah berstatus success (Berhasil) dan tidak dapat dibuat ulang.',
        409,
        'PAYMENT_ALREADY_SUCCESS'
      );
    }

    const shortId = order.order_id.split("-")[0].toUpperCase();
    const referensiSimulasi = `SIM-MVP-${shortId}-${Date.now()}`;

    // Kerjaan #5: Backend menetapkan status awal selalu "pending" (Menunggu)
    const saved = await paymentsRepository.createOrResetPendingPayment({
      orderId: order.order_id,
      pelangganId: order.pelanggan_id,
      penyediaId: order.penyedia_id,
      metodeSimulasi: metodeSimulasi || 'SIMULASI_MVP',
      nominal: order.harga_kesepakatan,
      referensiSimulasi,
      catatanSimulasi:
        catatan ||
        'Sesi simulasi pembayaran MVP berhasil dibuat oleh backend dengan status pending.',
    });

    await paymentsRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'INITIATE_PAYMENT_SIMULATION_PENDING',
      objekId: saved.payment_id,
      statusSebelum: existing ? existing.status_kode : null,
      statusSesudah: 'pending',
    });

    return saved;
  }

  /**
   * Kerjaan #2, #3, #4, #5, #6: Simulasi transisi pending -> success
   * Status order tetap "accepted" (terpisah), namun kini mengizinkan order lanjut ke "in_progress".
   */
  async simulateSuccess(orderId, user, payload = {}) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError(
        'Record payment belum ditemukan. Panggil POST /api/v1/payments terlebih dahulu untuk memulai sesi pending.',
        404,
        'PAYMENT_NOT_FOUND'
      );
    }

    // Kerjaan #4: Hanya pelanggan terkait yang dapat menjalankan simulasi
    this.assertOnlyCustomer(payment, user);

    if (payment.status_kode !== 'pending') {
      throw new AppError(
        `Transisi pembayaran ilegal: simulasi pending -> success hanya dapat dijalankan dari status 'pending' (status saat ini: '${payment.status_kode}').`,
        400,
        'INVALID_PAYMENT_TRANSITION'
      );
    }

    const updated = await paymentsRepository.updateSimulationStatus(orderId, {
      statusKode: 'success',
      statusPembayaran: PAYMENT_STATUS_LABEL.success,
      catatanSimulasi:
        payload.catatan ||
        'Simulasi pembayaran berhasil (pending -> success). Order kini diizinkan lanjut ke tahap in_progress oleh penyedia.',
    });

    await paymentsRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'SIMULATE_PAYMENT_SUCCESS',
      objekId: payment.payment_id,
      statusSebelum: 'pending',
      statusSesudah: 'success',
    });

    return updated;
  }

  /**
   * Kerjaan #2, #3, #4, #5, #7: Simulasi transisi pending -> failed
   * Pembayaran gagal TIDAK mengubah order menjadi in_progress.
   */
  async simulateFailed(orderId, user, payload = {}) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError(
        'Record payment belum ditemukan. Panggil POST /api/v1/payments terlebih dahulu untuk memulai sesi pending.',
        404,
        'PAYMENT_NOT_FOUND'
      );
    }

    // Kerjaan #4: Hanya pelanggan terkait yang dapat menjalankan simulasi
    this.assertOnlyCustomer(payment, user);

    if (payment.status_kode !== 'pending') {
      throw new AppError(
        `Transisi pembayaran ilegal: simulasi pending -> failed hanya dapat dijalankan dari status 'pending' (status saat ini: '${payment.status_kode}').`,
        400,
        'INVALID_PAYMENT_TRANSITION'
      );
    }

    const updated = await paymentsRepository.updateSimulationStatus(orderId, {
      statusKode: 'failed',
      statusPembayaran: PAYMENT_STATUS_LABEL.failed,
      catatanSimulasi:
        payload.alasan_gagal ||
        payload.catatan ||
        'Simulasi pembayaran gagal (pending -> failed). Order tertahan dan tidak dapat masuk ke in_progress.',
    });

    await paymentsRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'SIMULATE_PAYMENT_FAILED',
      objekId: payment.payment_id,
      statusSebelum: 'pending',
      statusSesudah: 'failed',
    });

    return updated;
  }

  async getPaymentByOrder(orderId, user) {
    const payment = await paymentsRepository.findByOrderId(orderId);
    if (!payment) {
      throw new AppError('Record payment belum ditemukan untuk order ini.', 404, 'PAYMENT_NOT_FOUND');
    }
    this.assertParticipant(payment, user);
    return payment;
  }

  async listMyPayments(userId) {
    return paymentsRepository.listByUser(userId);
  }
}

module.exports = new PaymentsService();