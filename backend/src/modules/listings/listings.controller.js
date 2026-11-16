const listingsService = require('./listings.service');
const { sendSuccess } = require('../../utils/response');

class ListingsController {
  async getCategories(req, res, next) {
    try {
      const data = await listingsService.listCategoriesAndSkills();
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar kategori dan keterampilan berhasil dimuat.',
        data,
      });
    } catch (error) {
      return next(error);
    }
  }

  async listDiscovery(req, res, next) {
    try {
      const { items, meta } = await listingsService.searchDiscovery(req.validated.query);
      const message =
        items.length === 0
          ? 'Tidak ada listing jasa aktif yang memenuhi kriteria pencarian.'
          : 'Daftar listing jasa berhasil dimuat.';

      return sendSuccess(res, { statusCode: 200, message, data: items, meta });
    } catch (error) {
      return next(error);
    }
  }

  async listMyGigs(req, res, next) {
    try {
      const items = await listingsService.getMyGigs(req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Daftar gig milik Anda berhasil dimuat.',
        data: items,
      });
    } catch (error) {
      return next(error);
    }
  }

  async getDetail(req, res, next) {
    try {
      const gig = await listingsService.getGigDetail(req.validated.params.id, req.user);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Detail gig berhasil dimuat.',
        data: gig,
      });
    } catch (error) {
      return next(error);
    }
  }

  async create(req, res, next) {
    try {
      const created = await listingsService.createGig(req.user.user_id, req.validated.body);
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Gig / listing jasa baru berhasil diterbitkan.',
        data: created,
      });
    } catch (error) {
      return next(error);
    }
  }

  async update(req, res, next) {
    try {
      const updated = await listingsService.updateGig(
        req.validated.params.id,
        req.user.user_id,
        req.validated.body
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Gig / listing jasa berhasil diperbarui.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async updateStatus(req, res, next) {
    try {
      const updated = await listingsService.updateGig(
        req.validated.params.id,
        req.user.user_id,
        { status: req.validated.body.status }
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: `Status publikasi gig berhasil diubah menjadi ${updated.status}.`,
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }

  async remove(req, res, next) {
    try {
      await listingsService.deleteGig(req.validated.params.id, req.user.user_id);
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Gig / listing jasa berhasil dihapus.',
        data: null,
      });
    } catch (error) {
      return next(error);
    }
  }

  async moderate(req, res, next) {
    try {
      const updated = await listingsService.moderateGig(
        req.validated.params.id,
        req.validated.body,
        req.user.user_id
      );
      return sendSuccess(res, {
        statusCode: 200,
        message: 'Status moderasi gig berhasil diperbarui oleh Administrator.',
        data: updated,
      });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = new ListingsController();
