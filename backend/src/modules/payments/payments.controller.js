const paymentsService = require('./payments.service');
const { sendSuccess } = require('../../utils/response');
const AppError = require('../../utils/AppError');

class PaymentsController {
  async initiate(req, res, next) {
    try {
      const created = await paymentsService.initiatePayment(req.user, req.validated.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Record pembayaran simulasi MVP berhasil dibuat dengan status awal pending (ditetapkan oleh backend).',
        data: created,
      });
    } catch (error) {
      return next(error);
    }
  }

  async simulateSuccess(req, res, next) {
    try {
      const updated = await paymentsService.simulateSuccess(
        req.validated.params.orderId,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Simulasi pembayaran berhasil (pending -> success). Status order tetap terpisah dan kini diizinkan lanjut ke in_progress.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async simulateFailed(req, res, next) {
    try {
      const updated = await paymentsService.simulateFailed(
        req.validated.params.orderId,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Simulasi pembayaran gagal (pending -> failed). Order tidak berubah menjadi in_progress.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async rejectDirectStatusPatch(req, res, next) {
    return next(
      new AppError(
        'Client dilarang menetapkan atau memaksa status pembayaran secara langsung. Gunakan action simulasi resmi pada environment demo/development.',
        400,
        'CLIENT_CANNOT_FORCE_STATUS'
      )
    );
  }

  async getByOrder(req, res, next) {
    try {
      const payment = await paymentsService.getPaymentByOrder(
        req.validated.params.orderId,
        req.user
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Detail simulasi pembayaran MVP berhasil dimuat.',
        data: payment,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listMine(req, res, next) {
    try {
      const items = await paymentsService.listMyPayments(req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar simulasi pembayaran MVP berhasil dimuat.',
        data: items,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new PaymentsController();