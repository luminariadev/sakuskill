const db = require('../../config/database');

class ListingsRepository {
  async findNearby({ lat, lng, radiusMeters, tipePenawaran }) {
    const params = [lng, lat, radiusMeters];
    let filterTypeClause = '';

    if (tipePenawaran) {
      params.push(tipePenawaran);
      filterTypeClause = 'AND sl.tipe_penawaran = $4';
    }

    const sql = [
      'SELECT',
      '  sl.listing_id,',
      '  sl.judul,',
      '  sl.deskripsi,',
      '  sl.harga,',
      '  sl.tipe_penawaran,',
      '  sl.status,',
      '  u.nama AS nama_penyedia,',
      '  s.nama_keterampilan,',
      '  s.kategori,',
      '  ROUND((ST_Distance(',
      '    sl.lokasi,',
      '    ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography',
      '  ) / 1000.0)::numeric, 2) AS jarak_km',
      'FROM service_listings sl',
      'JOIN users u ON u.user_id = sl.penyedia_id',
      'JOIN skills s ON s.skill_id = sl.skill_id',
      "WHERE sl.status = 'Aktif'",
      '  AND ST_DWithin(',
      '    sl.lokasi,',
      '    ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,',
      '    $3',
      '  )',
      '  ' + filterTypeClause,
      'ORDER BY jarak_km ASC;'
    ].join('\n');

    const { rows } = await db.query(sql, params);
    return rows;
  }
}

module.exports = new ListingsRepository();
