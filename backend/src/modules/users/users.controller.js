const usersService = require('./users.service');
const { sendSuccess } = require('../../utils/response');

class UsersController {
  async getMe(req, res, next) {
    try {
      const profile = await usersService.getMyProfile(req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Data profil berhasil dimuat.',
        data: profile,
      });
    } catch (error) {
      return next(error);
    }
  }

  async updateMe(req, res, next) {
    try {
      const updated = await usersService.updateMyProfile(req.user.user_id, req.validated.body);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Profil berhasil diperbarui.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async getPublicProfile(req, res, next) {
    try {
      const profile = await usersService.getPublicProfile(req.validated.params.id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Profil publik penyedia jasa berhasil dimuat.',
        data: profile,
      });
    } catch (error) {
      return next(error);
    }
  }

  async verifyUser(req, res, next) {
    try {
      const result = await usersService.verifyUserAccount(
        req.validated.params.id,
        req.validated.body.status_verifikasi,
        req.user.user_id
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Status verifikasi akun pengguna berhasil diperbarui oleh Administrator.',
        data: result,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new UsersController();
