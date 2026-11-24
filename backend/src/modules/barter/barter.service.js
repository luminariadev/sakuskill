const barterRepository = require('./barter.repository');
const AppError = require('../../utils/AppError');

const BARTER_STATUS_MAP = {
  requested: 'Diajukan',
  negotiating: 'Dalam Negosiasi',
  accepted: 'Disepakati',
  in_progress: 'Dikerjakan',
  completion_requested: 'Menunggu Konfirmasi',
  completed: 'Selesai',
  rejected: 'Ditolak',
  cancelled: 'Dibatalkan',
};

const NORMALIZE_BARTER_STATUS = {
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

class BarterService {
  assertParticipant(barter, user) {
    const isAdmin = user.peran === 'Administrator';
    const isInitiator = barter.pengaju_id === user.user_id;
    const isReceiver = barter.penerima_id === user.user_id;
    if (!isInitiator && !isReceiver && !isAdmin) {
      throw new AppError(
        'Akses ditolak. Pengguna di luar transaksi barter tidak dapat mengakses atau mengubah status barter ini.',
        403,
        'FORBIDDEN_NOT_PARTICIPANT'
      );
    }
    return { isInitiator, isReceiver, isAdmin };
  }

  async createBarterOffer(userId, payload) {
    const targetGig = await barterRepository.findGigById(payload.listing_id);
    if (!targetGig || targetGig.status !== 'Aktif') {
      throw new AppError(
        'Gig sasaran barter tidak ditemukan atau sedang tidak aktif.',
        404,
        'GIG_NOT_FOUND'
      );
    }

    const penerimaId = payload.penerima_id || targetGig.penyedia_id;
    if (penerimaId === userId || targetGig.penyedia_id === userId) {
      throw new AppError(
        'Anda tidak dapat mengajukan barter ke akun atau gig milik Anda sendiri.',
        400,
        'CANNOT_BARTER_WITH_SELF'
      );
    }

    if (payload.listing_pengaju_id) {
      const initiatorGig = await barterRepository.findGigById(payload.listing_pengaju_id);
      if (!initiatorGig || initiatorGig.penyedia_id !== userId) {
        throw new AppError(
          'listing_pengaju_id harus merujuk pada gig milik Anda sendiri.',
          400,
          'INVALID_INITIATOR_GIG'
        );
      }
    }

    const created = await barterRepository.createBarter({
      listingId: targetGig.listing_id,
      listingPengajuId: payload.listing_pengaju_id || null,
      pengajuId: userId,
      penerimaId,
      deskripsiJasaPengaju: payload.deskripsi_jasa_pengaju,
      deskripsiJasaPenerima: payload.deskripsi_jasa_penerima,
      tenggatPekerjaan: new Date(payload.tenggat_pekerjaan).toISOString(),
    });

    await barterRepository.writeAuditLog({
      aktorId: userId,
      aksi: 'CREATE_BARTER_OFFER',
      objekId: created.barter_id,
      statusSebelum: null,
      statusSesudah: 'requested',
    });

    return created;
  }

  async listMyBarters(userId) {
    return barterRepository.findByUser(userId);
  }

  async getBarterDetail(barterId, user) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    this.assertParticipant(barter, user);
    return barter;
  }

  async updateTerms(barterId, user, payload) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    const { isInitiator } = this.assertParticipant(barter, user);

    if (!['requested', 'negotiating', 'accepted'].includes(barter.status_kode)) {
      throw new AppError(
        `Deskripsi pekerjaan dan tenggat tidak dapat diubah karena status barter sudah '${barter.status_kode}'.`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    // Kerjaan #8: Jika satu pihak merevisi ketentuan, pihak lawan wajib menyetujui kembali sebelum in_progress
    const updated = await barterRepository.updateTerms(barterId, {
      deskripsiJasaPengaju: payload.deskripsi_jasa_pengaju,
      deskripsiJasaPenerima: payload.deskripsi_jasa_penerima,
      tenggatPekerjaan: payload.tenggat_pekerjaan
        ? new Date(payload.tenggat_pekerjaan).toISOString()
        : undefined,
      setujuPengaju: isInitiator,
      setujuPenerima: !isInitiator,
    });

    await barterRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'UPDATE_BARTER_TERMS',
      objekId: barterId,
      statusSebelum: barter.status_kode,
      statusSesudah: 'negotiating',
    });

    return updated;
  }

  async acceptBarter(barterId, user) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    const { isInitiator, isReceiver } = this.assertParticipant(barter, user);

    if (!['requested', 'negotiating'].includes(barter.status_kode)) {
      throw new AppError(
        `Transisi status ilegal: tidak dapat menyetujui barter dari status '${barter.status_kode}'.`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    const nextSetujuPengaju = isInitiator ? true : barter.setuju_pengaju;
    const nextSetujuPenerima = isReceiver ? true : barter.setuju_penerima;

    if (isInitiator && barter.setuju_pengaju && !barter.setuju_penerima) {
      throw new AppError(
        'Anda sudah menyetujui penawaran barter ini. Menunggu persetujuan pihak penerima.',
        400,
        'WAITING_OTHER_PARTY_CONSENT'
      );
    }

    const bothAgreed = Boolean(nextSetujuPengaju && nextSetujuPenerima);
    const nextStatusKode = bothAgreed ? 'accepted' : 'negotiating';

    const updated = await barterRepository.updateBarterState(barterId, {
      status: BARTER_STATUS_MAP[nextStatusKode],
      statusKode: nextStatusKode,
      setujuPengaju: nextSetujuPengaju,
      setujuPenerima: nextSetujuPenerima,
    });

    await barterRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'ACCEPT_BARTER',
      objekId: barterId,
      statusSebelum: barter.status_kode,
      statusSesudah: nextStatusKode,
    });

    return updated;
  }

  async startBarter(barterId, user) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    this.assertParticipant(barter, user);

    // Kerjaan #8: Kedua pihak HARUS menyetujui sebelum status in_progress
    if (!barter.setuju_pengaju || !barter.setuju_penerima || barter.status_kode !== 'accepted') {
      throw new AppError(
        'Transisi status ilegal: kedua pihak wajib menyetujui (status accepted) sebelum barter dapat dimulai (in_progress).',
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    const updated = await barterRepository.updateBarterState(barterId, {
      status: BARTER_STATUS_MAP.in_progress,
      statusKode: 'in_progress',
    });

    await barterRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'START_BARTER_IN_PROGRESS',
      objekId: barterId,
      statusSebelum: barter.status_kode,
      statusSesudah: 'in_progress',
    });

    return updated;
  }

  async confirmCompletion(barterId, user, payload = {}) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    const { isInitiator } = this.assertParticipant(barter, user);

    if (!['in_progress', 'completion_requested'].includes(barter.status_kode)) {
      throw new AppError(
        `Transisi status ilegal: konfirmasi penyelesaian hanya dapat dilakukan saat status 'in_progress' atau 'completion_requested' (status saat ini: '${barter.status_kode}').`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    const updated = await barterRepository.recordPartyCompletion({
      barterId,
      userId: user.user_id,
      isInitiator,
      catatan: payload.catatan,
    });

    await barterRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'CONFIRM_BARTER_COMPLETION',
      objekId: barterId,
      statusSebelum: barter.status_kode,
      statusSesudah: updated.status_kode,
    });

    return updated;
  }

  async rejectBarter(barterId, user, payload = {}) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    const { isReceiver } = this.assertParticipant(barter, user);
    if (!isReceiver) {
      throw new AppError(
        'Hanya pihak penerima penawaran barter yang dapat menolak (reject) pengajuan awal.',
        403,
        'FORBIDDEN_ROLE_ACTION'
      );
    }

    if (!['requested', 'negotiating'].includes(barter.status_kode)) {
      throw new AppError(
        `Transisi status ilegal: tidak dapat menolak barter dari status '${barter.status_kode}'.`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    const updated = await barterRepository.updateBarterState(barterId, {
      status: BARTER_STATUS_MAP.rejected,
      statusKode: 'rejected',
      alasanPembatalan: payload.alasan,
    });

    await barterRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'REJECT_BARTER',
      objekId: barterId,
      statusSebelum: barter.status_kode,
      statusSesudah: 'rejected',
    });

    return updated;
  }

  async cancelBarter(barterId, user, payload = {}) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    this.assertParticipant(barter, user);

    if (!['requested', 'negotiating', 'accepted'].includes(barter.status_kode)) {
      throw new AppError(
        `Transisi status ilegal: barter dengan status '${barter.status_kode}' tidak dapat dibatalkan secara sepihak.`,
        400,
        'INVALID_STATE_TRANSITION'
      );
    }

    const updated = await barterRepository.updateBarterState(barterId, {
      status: BARTER_STATUS_MAP.cancelled,
      statusKode: 'cancelled',
      alasanPembatalan: payload.alasan,
    });

    await barterRepository.writeAuditLog({
      aktorId: user.user_id,
      aksi: 'CANCEL_BARTER',
      objekId: barterId,
      statusSebelum: barter.status_kode,
      statusSesudah: 'cancelled',
    });

    return updated;
  }

  async transitionGeneric(barterId, user, body) {
    const target = NORMALIZE_BARTER_STATUS[String(body.status).toLowerCase().trim()];
    if (target === 'accepted') return this.acceptBarter(barterId, user);
    if (target === 'in_progress') return this.startBarter(barterId, user);
    if (target === 'completion_requested' || target === 'completed') {
      return this.confirmCompletion(barterId, user, body);
    }
    if (target === 'rejected') return this.rejectBarter(barterId, user, body);
    if (target === 'cancelled') return this.cancelBarter(barterId, user, body);

    throw new AppError(
      `Transisi status '${body.status}' tidak valid untuk siklus hidup barter.`,
      400,
      'INVALID_STATE_TRANSITION'
    );
  }

  async createReview(barterId, user, payload) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    const { isInitiator } = this.assertParticipant(barter, user);

    if (barter.status_kode !== 'completed') {
      throw new AppError(
        `Ulasan barter hanya dapat diberikan setelah kedua pihak mengonfirmasi selesai ('completed'). Status saat ini: '${barter.status_kode}'.`,
        400,
        'BARTER_NOT_COMPLETED'
      );
    }

    const existing = await barterRepository.findReviewByBarterAndAuthor(barterId, user.user_id);
    if (existing) {
      throw new AppError('Anda sudah memberikan ulasan untuk barter ini.', 409, 'REVIEW_ALREADY_EXISTS');
    }

    const penerimaId = isInitiator ? barter.penerima_id : barter.pengaju_id;
    return barterRepository.createBarterReview({
      barterId,
      pemberiId: user.user_id,
      penerimaId,
      rating: payload.rating,
      ratingKualitas: payload.rating_kualitas,
      ratingKetepatanWaktu: payload.rating_ketepatan_waktu,
      komentar: payload.komentar,
    });
  }

  async listMessages(barterId, user) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    this.assertParticipant(barter, user);
    return barterRepository.listMessages(barterId);
  }

  async sendMessage(barterId, user, payload) {
    const barter = await barterRepository.findById(barterId);
    if (!barter) {
      throw new AppError('Data kesepakatan barter tidak ditemukan.', 404, 'BARTER_NOT_FOUND');
    }
    this.assertParticipant(barter, user);
    return barterRepository.createMessage({
      barterId,
      senderId: user.user_id,
      isiPesan: payload.isi_pesan,
    });
  }
}

module.exports = new BarterService();