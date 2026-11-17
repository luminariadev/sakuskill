const reportsService = require('./reports.service');
const { sendSuccess } = require('../../utils/response');

class ReportsController {
  async create(req, res, next) {
    try {
      const result = await reportsService.submitReport(req.user.user_id, req.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Komplain/pengaduan berhasil diajukan.',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async listMine(req, res, next) {
    try {
      const result = await reportsService.getMyReports(req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar komplain saya berhasil dimuat.',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getDetail(req, res, next) {
    try {
      const result = await reportsService.getReportDetail(req.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Detail komplain berhasil dimuat.',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async listAdmin(req, res, next) {
    try {
      const result = await reportsService.listAllReports(req.query);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Seluruh komplain berhasil dimuat untuk admin.',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async resolve(req, res, next) {
    try {
      const result = await reportsService.resolveReport(req.params.id, req.user.user_id, req.body);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Status komplain berhasil diperbarui.',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReportsController();
