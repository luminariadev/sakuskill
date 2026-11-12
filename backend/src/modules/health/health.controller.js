const healthService = require('./health.service');
const { sendSuccess } = require('../../utils/response');

class HealthController {
  async check(req, res, next) {
    try {
      const healthData = await healthService.getSystemHealth();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Layanan SakuSkill API dan PostgreSQL/PostGIS beroperasi normal.',
        data: healthData,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new HealthController();
