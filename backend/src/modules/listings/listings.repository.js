const db = require('../../config/database');

class ListingsRepository {
  async getAllSkills() {
    const { rows } = await db.query(
      'SELECT skill_id, nama_keterampilan, kategori FROM skills ORDER BY kategori ASC, nama_keterampilan ASC'
    );
    return rows;
  }

  async resolveSkillId({ skillId, kategori }) {
    if (skillId) {
      const { rows } = await db.query(
        'SELECT skill_id, nama_keterampilan, kategori FROM skills WHERE skill_id = $1 LIMIT 1',
        [skillId]
      );
      return rows[0] || null;
    }
    if (kategori) {
      const { rows } = await db.query(
        `SELECT skill_id, nama_keterampilan, kategori
         FROM skills
         WHERE LOWER(kategori) = LOWER($1) OR LOWER(nama_keterampilan) = LOWER($1)
         ORDER BY skill_id ASC LIMIT 1`,
        [kategori]
      );
      return rows[0] || null;
    }
    return null;
  }

  async create({
    penyediaId,
    skillId,
    judul,
    deskripsi,
    harga,
    latitude,
    longitude,
    tipePenawaran,
    deskripsiImbalanBarter,
    status,
  }) {
    const sql = `
      INSERT INTO service_listings (
        penyedia_id, skill_id, judul, deskripsi, harga,
        lokasi, tipe_penawaran, deskripsi_imbalan_barter, status
      )
      VALUES (
        $1, $2, $3, $4, $5,
        ST_SetSRID(ST_MakePoint($6, $7), 4326)::geography,
        $8, $9, $10
      )
      RETURNING listing_id;
    `;
    const { rows } = await db.query(sql, [
      penyediaId,
      skillId,
      judul,
      deskripsi,
      harga,
      longitude,
      latitude,
      tipePenawaran,
      deskripsiImbalanBarter || null,
      status || 'Aktif',
    ]);
    return this.findById(rows[0].listing_id);
  }

  async findById(listingId, refCoords = null) {
    const distanceSelect = refCoords
      ? `ROUND((ST_Distance(sl.lokasi, ST_SetSRID(ST_MakePoint(${Number(refCoords.lng)}, ${Number(refCoords.lat)}), 4326)::geography) / 1000.0)::numeric, 2) AS jarak_km,`
      : `NULL::numeric AS jarak_km,`;

    const sql = `
      SELECT
        sl.listing_id,
        sl.penyedia_id,
        sl.skill_id,
        sl.judul,
        sl.deskripsi,
        sl.harga,
        sl.tipe_penawaran,
        sl.deskripsi_imbalan_barter,
        sl.status,
        ROUND(ST_Y(sl.lokasi::geometry)::numeric, 6) AS latitude,
        ROUND(ST_X(sl.lokasi::geometry)::numeric, 6) AS longitude,
        ${distanceSelect}
        sl.dibuat_pada,
        sl.diubah_pada,
        u.nama AS nama_penyedia,
        u.status_verifikasi AS verifikasi_penyedia,
        u.deskripsi_profil AS deskripsi_penyedia,
        s.nama_keterampilan,
        s.kategori,
        COALESCE(ROUND(AVG(r.rating)::numeric, 2), 0.00) AS rata_rata_rating,
        COUNT(r.review_id)::int AS jumlah_ulasan
      FROM service_listings sl
      JOIN users u ON u.user_id = sl.penyedia_id
      JOIN skills s ON s.skill_id = sl.skill_id
      LEFT JOIN reviews r
        ON r.penerima_id = sl.penyedia_id AND r.status_moderasi = 'Tampil'
      WHERE sl.listing_id = $1
      GROUP BY sl.listing_id, u.user_id, s.skill_id;
    `;
    const { rows } = await db.query(sql, [listingId]);
    if (rows.length === 0) return null;

    const item = rows[0];

    const { rows: portofolio } = await db.query(
      `SELECT portfolio_id, judul, deskripsi, berkas_ref, dibuat_pada
       FROM portfolio_items
       WHERE penyedia_id = $1
       ORDER BY dibuat_pada DESC LIMIT 6`,
      [item.penyedia_id]
    );

    const { rows: ulasan } = await db.query(
      `SELECT r.review_id, r.transaksi_tipe, r.rating, r.rating_kualitas,
              r.rating_ketepatan_waktu, r.komentar, r.dibuat_pada,
              u.nama AS nama_pemberi
       FROM reviews r
       JOIN users u ON u.user_id = r.pemberi_id
       WHERE r.penerima_id = $1 AND r.status_moderasi = 'Tampil'
       ORDER BY r.dibuat_pada DESC LIMIT 10`,
      [item.penyedia_id]
    );

    return {
      ...item,
      latitude: parseFloat(item.latitude),
      longitude: parseFloat(item.longitude),
      jarak_km: item.jarak_km !== null ? parseFloat(item.jarak_km) : null,
      rata_rata_rating: parseFloat(item.rata_rata_rating),
      portofolio_penyedia: portofolio,
      ulasan_terbaru: ulasan,
    };
  }

  async searchDiscovery({
    lat,
    lng,
    radiusMeters,
    useRadius,
    keyword,
    kategori,
    skillId,
    tipePenawaran,
    minHarga,
    maxHarga,
    minRating,
    penyediaId,
    sortBy,
    limit,
    offset,
  }) {
    const params = [lng, lat];
    const whereClauses = ["sl.status = 'Aktif'"];
    let paramIdx = 3;
    const nextPlaceholder = () => '$' + paramIdx++;

    if (useRadius) {
      params.push(radiusMeters);
      const pRadius = nextPlaceholder();
      whereClauses.push(
        `ST_DWithin(sl.lokasi, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, ${pRadius})`
      );
    }

    if (keyword) {
      params.push(`%${keyword}%`);
      const pKey = nextPlaceholder();
      whereClauses.push(
        `(sl.judul ILIKE ${pKey} OR sl.deskripsi ILIKE ${pKey} OR s.nama_keterampilan ILIKE ${pKey} OR s.kategori ILIKE ${pKey})`
      );
    }

    if (kategori) {
      params.push(kategori);
      const pKat = nextPlaceholder();
      whereClauses.push(`LOWER(s.kategori) = LOWER(${pKat})`);
    }

    if (skillId) {
      params.push(skillId);
      const pSkill = nextPlaceholder();
      whereClauses.push(`sl.skill_id = ${pSkill}`);
    }

    if (tipePenawaran) {
      params.push(tipePenawaran);
      const pTipe = nextPlaceholder();
      whereClauses.push(`sl.tipe_penawaran = ${pTipe}`);
    }

    if (minHarga !== undefined) {
      params.push(minHarga);
      const pMin = nextPlaceholder();
      whereClauses.push(`sl.harga >= ${pMin}`);
    }

    if (maxHarga !== undefined) {
      params.push(maxHarga);
      const pMax = nextPlaceholder();
      whereClauses.push(`sl.harga <= ${pMax}`);
    }

    if (penyediaId) {
      params.push(penyediaId);
      const pPenyedia = nextPlaceholder();
      whereClauses.push(`sl.penyedia_id = ${pPenyedia}`);
    }

    let havingClause = '';
    if (minRating !== undefined) {
      params.push(minRating);
      const pRating = nextPlaceholder();
      havingClause = `HAVING COALESCE(AVG(r.rating), 0) >= ${pRating}`;
    }

    const orderMap = {
      jarak: 'jarak_km ASC, sl.dibuat_pada DESC',
      harga_asc: 'sl.harga ASC, jarak_km ASC',
      harga_desc: 'sl.harga DESC, jarak_km ASC',
      rating: 'rata_rata_rating DESC, jumlah_ulasan DESC, jarak_km ASC',
      terbaru: 'sl.dibuat_pada DESC',
    };
    const orderByClause = orderMap[sortBy] || orderMap.jarak;

    params.push(limit, offset);
    const pLimit = nextPlaceholder();
    const pOffset = nextPlaceholder();

    const sql = `
      SELECT
        sl.listing_id,
        sl.penyedia_id,
        sl.skill_id,
        sl.judul,
        sl.deskripsi,
        sl.harga,
        sl.tipe_penawaran,
        sl.deskripsi_imbalan_barter,
        sl.status,
        ROUND(ST_Y(sl.lokasi::geometry)::numeric, 6) AS latitude,
        ROUND(ST_X(sl.lokasi::geometry)::numeric, 6) AS longitude,
        ROUND((ST_Distance(
          sl.lokasi,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) / 1000.0)::numeric, 2) AS jarak_km,
        u.nama AS nama_penyedia,
        u.status_verifikasi AS verifikasi_penyedia,
        s.nama_keterampilan,
        s.kategori,
        COALESCE(ROUND(AVG(r.rating)::numeric, 2), 0.00) AS rata_rata_rating,
        COUNT(r.review_id)::int AS jumlah_ulasan,
        sl.dibuat_pada
      FROM service_listings sl
      JOIN users u ON u.user_id = sl.penyedia_id
      JOIN skills s ON s.skill_id = sl.skill_id
      LEFT JOIN reviews r
        ON r.penerima_id = sl.penyedia_id AND r.status_moderasi = 'Tampil'
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY sl.listing_id, u.user_id, s.skill_id
      ${havingClause}
      ORDER BY ${orderByClause}
      LIMIT ${pLimit} OFFSET ${pOffset};
    `;

    const { rows } = await db.query(sql, params);
    return rows.map((row) => ({
      ...row,
      latitude: parseFloat(row.latitude),
      longitude: parseFloat(row.longitude),
      jarak_km: parseFloat(row.jarak_km),
      rata_rata_rating: parseFloat(row.rata_rata_rating),
    }));
  }

  async findByOwner(penyediaId) {
    const sql = `
      SELECT
        sl.listing_id,
        sl.penyedia_id,
        sl.skill_id,
        sl.judul,
        sl.deskripsi,
        sl.harga,
        sl.tipe_penawaran,
        sl.deskripsi_imbalan_barter,
        sl.status,
        ROUND(ST_Y(sl.lokasi::geometry)::numeric, 6) AS latitude,
        ROUND(ST_X(sl.lokasi::geometry)::numeric, 6) AS longitude,
        s.nama_keterampilan,
        s.kategori,
        sl.dibuat_pada,
        sl.diubah_pada
      FROM service_listings sl
      JOIN skills s ON s.skill_id = sl.skill_id
      WHERE sl.penyedia_id = $1
      ORDER BY sl.dibuat_pada DESC;
    `;
    const { rows } = await db.query(sql, [penyediaId]);
    return rows.map((r) => ({
      ...r,
      latitude: parseFloat(r.latitude),
      longitude: parseFloat(r.longitude),
    }));
  }

  async update(listingId, fieldsToUpdate) {
    const setClauses = ['diubah_pada = NOW()'];
    const values = [];
    let idx = 1;
    const nextParam = () => '$' + idx++;

    const columnMap = {
      skillId: 'skill_id',
      judul: 'judul',
      deskripsi: 'deskripsi',
      harga: 'harga',
      tipePenawaran: 'tipe_penawaran',
      deskripsiImbalanBarter: 'deskripsi_imbalan_barter',
      status: 'status',
    };

    for (const [key, column] of Object.entries(columnMap)) {
      if (fieldsToUpdate[key] !== undefined) {
        setClauses.push(`${column} = ${nextParam()}`);
        values.push(fieldsToUpdate[key]);
      }
    }

    if (fieldsToUpdate.latitude !== undefined && fieldsToUpdate.longitude !== undefined) {
      const pLng = nextParam();
      const pLat = nextParam();
      setClauses.push(
        `lokasi = ST_SetSRID(ST_MakePoint(${pLng}, ${pLat}), 4326)::geography`
      );
      values.push(fieldsToUpdate.longitude, fieldsToUpdate.latitude);
    }

    values.push(listingId);
    const pId = nextParam();
    const sql = `
      UPDATE service_listings
      SET ${setClauses.join(', ')}
      WHERE listing_id = ${pId}
      RETURNING listing_id;
    `;
    await db.query(sql, values);
    return this.findById(listingId);
  }

  async hasActiveTransactions(listingId) {
    const orderCheck = await db.query(
      `SELECT 1 FROM orders
       WHERE listing_id = $1
         AND status_pesanan NOT IN ('Selesai', 'Dibatalkan', 'Ditolak')
       LIMIT 1`,
      [listingId]
    );
    if (orderCheck.rowCount > 0) return true;

    const barterCheck = await db.query(
      `SELECT 1 FROM barter_agreements
       WHERE listing_id = $1
         AND status NOT IN ('Selesai', 'Dibatalkan', 'Ditolak')
       LIMIT 1`,
      [listingId]
    );
    return barterCheck.rowCount > 0;
  }

  async deleteById(listingId) {
    await db.query('DELETE FROM service_listings WHERE listing_id = $1', [listingId]);
  }

  async writeAuditLog({ aktorId, aksi, objekId, statusSebelum, statusSesudah }) {
    await db.query(
      `INSERT INTO audit_logs (aktor_id, aksi, objek_tipe, objek_id, status_sebelum, status_sesudah)
       VALUES ($1, $2, 'ServiceListings', $3, $4, $5)`,
      [aktorId, aksi, objekId, statusSebelum, statusSesudah]
    );
  }
}

module.exports = new ListingsRepository();
