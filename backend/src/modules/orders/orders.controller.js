const ordersService = require('./orders.service');
const { sendSuccess } = require('../../utils/response');

class OrdersController {
  async create(req, res, next) {
    try {
      const created = await ordersService.createOrder(req.user.user_id, req.validated.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Order berhasil dibuat dengan snapshot harga dan ketentuan gig.',
        data: created,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listMine(req, res, next) {
    try {
      const orders = await ordersService.listMyOrders(req.user.user_id, req.query);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar order berhasil dimuat.',
        data: orders,
      });
    } catch (error) {
      return next(error);
    }
  }

  async getDetail(req, res, next) {
    try {
      const order = await ordersService.getOrderDetail(req.validated.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Detail order berhasil dimuat.',
        data: order,
      });
    } catch (error) {
      return next(error);
    }
  }

  async propose(req, res, next) {
    try {
      const updated = await ordersService.submitProposal(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Proposal kesepakatan scope, harga final, dan deadline berhasil diajukan.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async accept(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        'accepted',
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Order disetujui (accepted). Kesepakatan scope, harga final, dan deadline telah dikunci.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async reject(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        'rejected',
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Order telah ditolak (rejected) oleh Penyedia Jasa.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async startWork(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        'in_progress'
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Status order diubah menjadi sedang dikerjakan (in_progress).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async requestCompletion(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        'completion_requested'
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Penyelesaian pekerjaan diajukan (completion_requested). Menunggu konfirmasi pelanggan.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async complete(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        'completed'
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Pelanggan telah mengonfirmasi pekerjaan selesai (completed).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async cancel(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        'cancelled',
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Order berhasil dibatalkan (cancelled).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async updateStatusGeneric(req, res, next) {
    try {
      const updated = await ordersService.transitionStatus(
        req.validated.params.id,
        req.user,
        req.validated.body.status,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: `Status order berhasil diperbarui menjadi ${updated.status_kode} (${updated.status_pesanan}).`,
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async createReview(req, res, next) {
    try {
      const review = await ordersService.createReview(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Ulasan untuk order yang telah selesai berhasil disimpan.',
        data: review,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listMessages(req, res, next) {
    try {
      const messages = await ordersService.listOrderMessages(
        req.validated.params.id,
        req.user
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Riwayat pesan order berhasil dimuat.',
        data: messages,
      });
    } catch (error) {
      return next(error);
    }
  }

  async sendMessage(req, res, next) {
    try {
      const created = await ordersService.sendOrderMessage(
        req.validated.params.id,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Pesan berhasil dikirim.',
        data: created,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new OrdersController();