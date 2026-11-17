const adminService = require('./admin.service');
const { sendSuccess } = require('../../utils/response');

class AdminController {
  async getDashboard(req, res, next) {
    try {
      const data = await adminService.getDashboard();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Dasbor operasional berhasil dimuat.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async getUsers(req, res, next) {
    try {
      const data = await adminService.getUsers();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar pengguna dan antrean verifikasi KTM berhasil dimuat.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async verifyUser(req, res, next) {
    try {
      const { status, notes } = req.body;
      const data = await adminService.verifyUser(req.params.id, status, notes);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Status verifikasi KTM berhasil diperbarui.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async sanctionUser(req, res, next) {
    try {
      const { action, notes } = req.body;
      const data = await adminService.sanctionUser(req.params.id, action, notes);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Sanksi akun pengguna berhasil diterapkan.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async getListings(req, res, next) {
    try {
      const data = await adminService.getListings();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Katalog layanan mahasiswa berhasil dimuat.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async moderateListing(req, res, next) {
    try {
      const { action, notes } = req.body;
      const data = await adminService.moderateListing(req.params.id, action, notes);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Tindakan moderasi layanan berhasil dieksekusi.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async getDisputes(req, res, next) {
    try {
      const data = await adminService.getDisputes();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar perkara sidang mediasi & sengketa berhasil dimuat.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async resolveDispute(req, res, next) {
    try {
      const { verdict, notes } = req.body;
      const data = await adminService.resolveDispute(req.params.id, verdict, notes);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Putusan arbitrase resmi berhasil dikirim dan escrow dieksekusi.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async getReports(req, res, next) {
    try {
      const data = await adminService.getReports();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar laporan & aduan pengguna berhasil dimuat.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async resolveReport(req, res, next) {
    try {
      const { action, notes } = req.body;
      const data = await adminService.resolveReport(req.params.id, action, notes);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Laporan berhasil ditindaklanjuti dan diselesaikan.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }

  async getEscrowTransactions(req, res, next) {
    try {
      const data = await adminService.getEscrowTransactions();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Data monitoring transaksi & saldo penampungan simulasi berhasil dimuat.',
        data,
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AdminController();
