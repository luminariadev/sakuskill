const barterService = require('./barter.service');
const { sendSuccess } = require('../../utils/response');

class BarterController {
  async create(req, res, next) {
    try {
      const created = await barterService.createBarterOffer(req.user.user_id, req.validated.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Penawaran barter berhasil diajukan. Menunggu persetujuan pihak penerima.',
        data: created,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listMine(req, res, next) {
    try {
      const items = await barterService.listMyBarters(req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar transaksi barter berhasil dimuat.',
        data: items,
      });
    } catch (error) {
      return next(error);
    }
  }

  async getDetail(req, res, next) {
    try {
      const item = await barterService.getBarterDetail(req.validated.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Detail kesepakatan barter berhasil dimuat.',
        data: item,
      });
    } catch (error) {
      return next(error);
    }
  }

  async updateTerms(req, res, next) {
    try {
      const updated = await barterService.updateTerms(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Deskripsi pekerjaan dan tenggat barter diperbarui. Menunggu persetujuan ulang pihak lawan.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async accept(req, res, next) {
    try {
      const updated = await barterService.acceptBarter(req.validated.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Kesepakatan barter telah disetujui oleh kedua belah pihak (accepted).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async reject(req, res, next) {
    try {
      const updated = await barterService.rejectBarter(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Penawaran barter telah ditolak (rejected).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async startWork(req, res, next) {
    try {
      const updated = await barterService.startBarter(req.validated.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Barter resmi dimulai (in_progress) setelah kedua pihak menyetujui.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async confirmCompletion(req, res, next) {
    try {
      const updated = await barterService.confirmCompletion(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      const isFullyCompleted = updated.status_kode === 'completed';
      return sendSuccess(res, {
        statusCode: 200,
        message: isFullyCompleted
          ? 'Kedua pihak telah mengonfirmasi penyelesaian. Barter resmi selesai (completed)!'
          : 'Konfirmasi penyelesaian Anda telah dicatat (completion_requested). Menunggu konfirmasi pihak kedua sebelum ditandai selesai.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async cancel(req, res, next) {
    try {
      const updated = await barterService.cancelBarter(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Kesepakatan barter telah dibatalkan (cancelled).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async updateStatusGeneric(req, res, next) {
    try {
      const updated = await barterService.transitionGeneric(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: `Status barter berhasil diperbarui menjadi ${updated.status_kode} (${updated.status}).`,
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async createReview(req, res, next) {
    try {
      const review = await barterService.createReview(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Ulasan barter berhasil disimpan.',
        data: review,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listMessages(req, res, next) {
    try {
      const messages = await barterService.listMessages(req.validated.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Pesan diskusi barter berhasil dimuat.',
        data: messages,
      });
    } catch (error) {
      return next(error);
    }
  }

  async sendMessage(req, res, next) {
    try {
      const message = await barterService.sendMessage(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Pesan barter terkirim.',
        data: message,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new BarterController();