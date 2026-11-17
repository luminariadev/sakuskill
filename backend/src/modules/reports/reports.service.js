const reportsRepository = require('./reports.repository');
const AppError = require('../../utils/AppError');

class ReportsService {
  async submitReport(userId, payload) {
    const report = await reportsRepository.createReport({
      pelaporId: userId,
      targetTipe: payload.target_tipe,
      targetId: payload.target_id,
      alasan: payload.alasan,
      keterangan: payload.keterangan,
    });
    return report;
  }

  async getMyReports(userId) {
    return reportsRepository.listByUser(userId);
  }

  async getReportDetail(reportId, user) {
    const report = await reportsRepository.findById(reportId);
    if (!report) {
      throw new AppError('Pengaduan/komplain tidak ditemukan.', 404, 'REPORT_NOT_FOUND');
    }
    const isOwner = report.pelapor_id === user.user_id;
    const isAdmin = user.peran === 'Administrator';
    if (!isOwner && !isAdmin) {
      throw new AppError('Akses ditolak ke laporan ini.', 403, 'FORBIDDEN');
    }
    return report;
  }

  async listAllReports(query) {
    return reportsRepository.listAll(query);
  }

  async resolveReport(reportId, adminId, payload) {
    const report = await reportsRepository.findById(reportId);
    if (!report) {
      throw new AppError('Pengaduan/komplain tidak ditemukan.', 404, 'REPORT_NOT_FOUND');
    }
    return reportsRepository.updateResolution(reportId, {
      statusPenanganan: payload.status_penanganan,
      keputusan: payload.keputusan,
      ditanganiOleh: adminId,
    });
  }
}

module.exports = new ReportsService();
