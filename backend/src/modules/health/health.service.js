const healthRepository = require('./health.repository');
const AppError = require('../../utils/AppError');

class HealthService {
  async getSystemHealth() {
    try {
      const dbStatus = await healthRepository.checkDatabaseAndPostgis();
      return {
        status: 'UP',
        service: 'SakuSkill Backend API',
        uptime_seconds: Math.floor(process.uptime()),
        timestamp: new Date().toISOString(),
        database: {
          connected: true,
          name: dbStatus.database_name,
          server_time: dbStatus.server_time,
          postgis_enabled: Boolean(dbStatus.postgis_version),
        },
      };
    } catch (error) {
      throw new AppError(
        'Koneksi ke basis data PostgreSQL/PostGIS gagal diverifikasi.',
        503,
        'DATABASE_UNAVAILABLE',
        { reason: error.message }
      );
    }
  }
}

module.exports = new HealthService();
