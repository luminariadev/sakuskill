const ordersRepository = require('./orders.repository');
const paymentsRepository = require('../payments/payments.repository');
const AppError = require('../../utils/AppError');

const ORDER_STATUS_MAP = {
  requested: 'Diajukan',
  negotiating: 'Dalam Negosiasi',
  accepted: 'Disepakati',
  in_progress: 'Dikerjakan',
  completion_requested: 'Menunggu Konfirmasi',
  completed: 'Selesai',
  rejected: 'Ditolak',
  cancelled: 'Dibatalkan',
};

const NORMALIZE_STATUS_INPUT = {
  requested: 'requested',
  diajukan: 'requested',
  negotiating: 'negotiating',
  'dalam negosiasi': 'negotiating',
  accepted: 'accepted',
  disepakati: 'accepted',
  in_progress: 'in_progress',
  dikerjakan: 'in_progress',
  completion_requested: 'completion_requested',
  'menunggu konfirmasi': 'completion_requested',
  completed: 'completed',
  selesai: 'completed',
  rejected: 'rejected',
  ditolak: 'rejected',
  cancelled: 'cancelled',
  canceled: 'cancelled',
  dibatalkan: 'cancelled',
};

class OrdersService {
  assertParticipant(order, user) {
    const isAdmin = user.peran === 'Administrator';
    const isCustomer = order.pelanggan_id === user.user_id;
    const isProvider = order.penyedia_id === user.user_id;
    if (!isCustomer && !isProvider && !isAdmin) {
      throw new AppError(
        'Akses ditolak. Pengguna di luar transaksi tidak diizinkan mengakses atau mengubah status order ini.',
        403,
        'FORBIDDEN_NOT_PARTICIPANT'
      );
    }
    return { isCustomer, isProvider, isAdmin };
  }

  async createOrder(userId, payload) {
    const gig = await ordersRepository.findGigForOrder(payload.listing_id);
    if (!gig || gig.status !== 'Aktif') {
      throw new AppError(
        'Gig / layanan tidak ditemukan atau sedang tidak aktif.',
        404,
        'GIG_NOT_FOUND'
      );
    }

    if (gig.penyedia_id === userId) {
      throw new AppError(
        'Anda tidak dapat membuat pesanan (order) pada gig milik Anda sendiri.',
        400,
        'CANNOT_ORDER_OWN_GIG'
      );
    }

    if (gig.tipe_penawaran === 'Barter') {
      throw new AppError(
        'Gig ini hanya menerima penawaran Barter. Gunakan endpoint /api/v1/barter.',
        400,
        'GIG_BARTER_ONLY'
      );
    }

    const scopeText = (payload.ruang_lingkup || payload.catatan_kebutuhan).trim();
    const finalPrice =
      payload.harga_kesepakatan !== undefined ? Number(payload.harga_kesepakatan) : Number(gig.harga);
    const deadlineDate = new Date(payload.tenggat_pekerjaan);

    const created = await ordersRepository.createOrder({
      listingId: gig.listing_id,
      pelangganId: userId,
      penyediaId: gig.penyedia_id,
      snapshotJudul: gig.judul,
      snapshotHarga: gig.harga,
      snapshotKetentuan: gig.deskripsi,
      ruangLingkup: scopeText,
      hargaKesepakatan: finalPrice,
      tenggatPekerjaan: deadlineDate.toISOString(),
    });

    await ordersRepository.writeAuditLog({
      aktorId: userId,
      aksi: 'CREATE_ORDER',
      objekId: created.order_id,
      statusSebelum: null,
      statusSesudah: 'requested',
    });

    return created;
  }

  async listMyOrders(userId, query = {}) {
    return ordersRepository.findByUser(userId, query);
  }

  async getOrderDetail(orderId, user) {
    const order = await ordersRepository.findById(orderId);
    if (!order) {
      throw new AppError('Data order tidak ditemukan.', 404, 'ORDER_NOT_FOUND');
    }
    this.assertParticipant(order, user);
    const payment = await paymentsRepository.findByOrderId(orderId);
    return { ...order, payment };
  }

  async submitProposal(orderId, user, payload) {
    const order = await ordersRepository.findById(orderId);
    if (!order) {
      throw new AppError('Data order tidak ditemukan.', 404, 'ORDER_NOT_FOUND');
    }
    this.assertParticipant(order, user);

    if (!['requested', 'negotiating'].includes(order.status_kode)) {
      throw new AppError(
        `Proposal negosiasi tidak dapat diajukan karena status order saat ini adalah '${order.status_kode}'.`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    const updated = await ordersRepository.addProposal({
      orderId,
      pengajuId: user.user_id,
      hargaTawaran: payload.harga_tawaran,
      deskripsiRuangLingkup: payload.deskripsi_ruang_lingkup,
      tenggatUsulan: payload.tenggat_usulan ? new Date(payload.tenggat_usulan).toISOString() : null,
    });

    await ordersRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'PROPOSE_ORDER_TERMS',
      objekId: orderId,
      statusSebelum: order.status_kode,
      statusSesudah: 'negotiating',
    });

    return updated;
  }

  async transitionStatus(orderId, user, targetStatusInput, extraPayload = {}) {
    const order = await ordersRepository.findById(orderId);
    if (!order) {
      throw new AppError('Data order tidak ditemukan.', 404, 'ORDER_NOT_FOUND');
    }

    const { isCustomer, isProvider } = this.assertParticipant(order, user);

    const normalizedTarget = NORMALIZE_STATUS_INPUT[String(targetStatusInput).toLowerCase().trim()];
    if (!normalizedTarget) {
      throw new AppError(
        `Target status '${targetStatusInput}' tidak dikenali dalam siklus hidup order.`,
        400,
        'INVALID_STATUS_VALUE'
      );
    }

    const currentStatus = order.status_kode;

    const transitionRules = {
      accepted: {
        allowedFrom: ['requested', 'negotiating'],
        actorCheck: () => isProvider,
        actorError: 'Hanya Penyedia Jasa yang dapat menyetujui (accept) order.',
      },
      rejected: {
        allowedFrom: ['requested', 'negotiating'],
        actorCheck: () => isProvider,
        actorError: 'Hanya Penyedia Jasa yang dapat menolak (reject) order.',
      },
      in_progress: {
        allowedFrom: ['accepted'],
        actorCheck: () => isProvider,
        actorError: 'Hanya Penyedia Jasa yang dapat memulai pengerjaan (in_progress).',
      },
      completion_requested: {
        allowedFrom: ['in_progress'],
        actorCheck: () => isProvider,
        actorError: 'Hanya Penyedia Jasa yang dapat mengajukan klaim selesai (completion_requested).',
      },
      completed: {
        allowedFrom: ['completion_requested'],
        actorCheck: () => isCustomer,
        actorError: 'Hanya Pelanggan yang dapat mengonfirmasi penyelesaian akhir (completed).',
      },
      cancelled: {
        allowedFrom: ['requested', 'negotiating', 'accepted'],
        actorCheck: () => isCustomer,
        actorError: 'Hanya Pelanggan yang dapat membatalkan (cancel) order sebelum pengerjaan dimulai.',
      },
    };

    const rule = transitionRules[normalizedTarget];
    if (!rule || !rule.allowedFrom.includes(currentStatus)) {
      throw new AppError(
        `Transisi status ilegal: tidak dapat mengubah status order dari '${currentStatus}' menjadi '${normalizedTarget}'.`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    if (!rule.actorCheck()) {
      throw new AppError(rule.actorError, 403, 'FORBIDDEN_ROLE_ACTION');
    }

    // Kerjaan #6 & #7: Order HANYA boleh lanjut ke in_progress setelah payment berstatus "success"!
    const paymentRecord = await paymentsRepository.findByOrderId(orderId);
    if (normalizedTarget === 'in_progress') {
      if (!paymentRecord) {
        throw new AppError(
          'Order belum dapat dimulai (in_progress) karena pelanggan belum melakukan simulasi pembayaran (record payment belum ada).',
          400,
          'PAYMENT_REQUIRED_BEFORE_START'
        );
      }
      if (paymentRecord.status_kode !== 'success') {
        throw new AppError(
          `Order tidak dapat dilanjutkan ke 'in_progress' karena status pembayaran saat ini adalah '${paymentRecord.status_kode}' (${paymentRecord.status_pembayaran}). Order hanya boleh lanjut setelah payment 'success'.`,
          400,
          'PAYMENT_REQUIRED_BEFORE_START'
        );
      }
    }

    const updated = await ordersRepository.updateOrderState(orderId, {
      statusPesanan: ORDER_STATUS_MAP[normalizedTarget],
      statusKode: normalizedTarget,
      ruangLingkup: extraPayload.ruang_lingkup,
      hargaKesepakatan: extraPayload.harga_kesepakatan,
      tenggatPekerjaan: extraPayload.tenggat_pekerjaan
        ? new Date(extraPayload.tenggat_pekerjaan).toISOString()
        : undefined,
      alasanPembatalan: extraPayload.alasan,
      markCompletedNow: normalizedTarget === 'completed',
    });

    await ordersRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'ORDER_STATUS_' + normalizedTarget.toUpperCase(),
      objekId: orderId,
      statusSebelum: currentStatus,
      statusSesudah: normalizedTarget,
    });

    const latestPayment = await paymentsRepository.findByOrderId(orderId);
    return { ...updated, payment: latestPayment };
  }

  async createReview(orderId, user, payload) {
    const order = await ordersRepository.findById(orderId);
    if (!order) {
      throw new AppError('Data order tidak ditemukan.', 404, 'ORDER_NOT_FOUND');
    }

    const { isCustomer } = this.assertParticipant(order, user);
    if (!isCustomer) {
      throw new AppError(
        'Hanya Pelanggan pada order ini yang dapat memberikan ulasan layanan.',
        403,
        'FORBIDDEN_ROLE_ACTION'
      );
    }

    if (order.status_kode !== 'completed') {
      throw new AppError(
        `Ulasan (review) hanya dapat diberikan setelah order berstatus 'completed' (status saat ini: '${order.status_kode}').`,
        400,
        'ORDER_NOT_COMPLETED'
      );
    }

    const existingReview = await ordersRepository.findReviewByOrderAndAuthor(orderId, user.user_id);
    if (existingReview) {
      throw new AppError(
        'Anda sudah memberikan ulasan untuk order ini.',
        409,
        'REVIEW_ALREADY_EXISTS'
      );
    }

    const review = await ordersRepository.createReview({
      orderId,
      pemberiId: user.user_id,
      penerimaId: order.penyedia_id,
      rating: payload.rating,
      ratingKualitas: payload.rating_kualitas,
      ratingKetepatanWaktu: payload.rating_ketepatan_waktu,
      komentar: payload.komentar,
    });

    return review;
  }
}

module.exports = new OrdersService();