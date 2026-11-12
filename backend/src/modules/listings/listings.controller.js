const listingsService = require('./listings.service');
const { sendSuccess } = require('../../utils/response');

class ListingsController {
  async listNearby(req, res, next) {
    try {
      const { items, meta } = await listingsService.searchHyperlocal(req.validated.query);
      const message =
        items.length === 0
          ? 'Tidak ada listing jasa aktif yang memenuhi kriteria pada radius tersebut.'
          : 'Daftar listing hyperlocal berhasil dimuat.';

      return sendSuccess(res, { statusCode: 200, message, data: items, meta });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new ListingsController();
