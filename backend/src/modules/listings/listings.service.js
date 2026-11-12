const listingsRepository = require('./listings.repository');
const env = require('../../config/env');

class ListingsService {
  async searchHyperlocal(queryParams) {
    const lat = queryParams.lat ?? env.hyperlocal.defaultLat;
    const lng = queryParams.lng ?? env.hyperlocal.defaultLng;
    const radiusMeters = queryParams.radius_m ?? env.hyperlocal.defaultRadiusMeters;

    const items = await listingsRepository.findNearby({
      lat,
      lng,
      radiusMeters,
      tipePenawaran: queryParams.tipe_penawaran,
    });

    return {
      items,
      meta: {
        titik_acuan: { lat, lng },
        radius_meter: radiusMeters,
        total: items.length,
      },
    };
  }
}

module.exports = new ListingsService();
