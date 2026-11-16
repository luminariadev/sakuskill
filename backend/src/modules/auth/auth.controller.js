const authService = require('./auth.service');
const { sendSuccess } = require('../../utils/response');

class AuthController {
  async register(req, res, next) {
    try {
      const result = await authService.register(req.validated.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Registrasi akun berhasil.',
        data: result,
      });
    } catch (error) {
      return next(error);
    }
  }

  async login(req, res, next) {
    try {
      const result = await authService.login(req.validated.body);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Autentikasi berhasil.',
        data: result,
      });
    } catch (error) {
      return next(error);
    }
  }

  async logout(req, res, next) {
    try {
      await authService.logout(req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Berhasil keluar (logout). Sesi telah diakhiri.',
        data: null,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new AuthController();
