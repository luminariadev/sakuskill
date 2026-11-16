const paymentsService = require('./payments.service');
const { sendSuccess } = require('../../utils/response');

class PaymentsController {
  async checkout(req, res, next) {
    try {
      const created = await paymentsService.createCheckout(req.user, req.validated.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Tagihan pembayaran berhasil dibuat melalui Payment Gateway Eksternal. Silakan selesaikan pembayaran agar dana masuk ke Escrow.',
        data: created,
      });
    } catch (error) {
      return next(error);
    }
  }

  async webhook(req, res, next) {
    try {
      const updated = await paymentsService.handleGatewayWebhook(req.validated.body);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Notifikasi webhook Payment Gateway berhasil diproses.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async simulatePay(req, res, next) {
    try {
      const updated = await paymentsService.simulatePaymentSettlement(
        req.validated.params.orderId,
        req.user
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Pembayaran berhasil diselesaikan (settlement). Dana kini ditahan dengan aman di Rekening Bersama (Escrow).',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async releaseEscrow(req, res, next) {
    try {
      const updated = await paymentsService.releaseEscrow(
        req.validated.params.orderId,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Dana Escrow telah resmi dilepas (released) kepada Penyedia Jasa.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async refundEscrow(req, res, next) {
    try {
      const updated = await paymentsService.refundEscrow(
        req.validated.params.orderId,
        req.user,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Dana Escrow telah dikembalikan (refunded) kepada Pelanggan.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async getByOrder(req, res, next) {
    try {
      const payment = await paymentsService.getPaymentByOrder(
        req.validated.params.orderId,
        req.user
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Detail pembayaran dan status Escrow berhasil dimuat.',
        data: payment,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listMine(req, res, next) {
    try {
      const result = await paymentsService.listMyPayments(req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Ringkasan Rekening Bersama (Escrow) dan daftar pembayaran berhasil dimuat.',
        data: result.items,
        meta: result.summary,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new PaymentsController();