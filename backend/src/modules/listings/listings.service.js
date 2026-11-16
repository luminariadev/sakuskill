const listingsRepository = require('./listings.repository');
const env = require('../../config/env');
const AppError = require('../../utils/AppError');

class ListingsService {
  async listCategoriesAndSkills() {
    const skills = await listingsRepository.getAllSkills();
    const categories = [...new Set(skills.map((s) => s.kategori))];
    return { categories, skills };
  }

  async searchDiscovery(queryParams) {
    const lat = queryParams.lat ?? env.hyperlocal.defaultLat;
    const lng = queryParams.lng ?? env.hyperlocal.defaultLng;
    const radiusMeters = queryParams.radius_m ?? env.hyperlocal.defaultRadiusMeters;
    const useRadius = queryParams.use_radius !== false;
    const keyword = queryParams.q || queryParams.search || null;
    const page = queryParams.page || 1;
    const limit = queryParams.limit || 20;
    const offset = (page - 1) * limit;

    const items = await listingsRepository.searchDiscovery({
      lat,
      lng,
      radiusMeters,
      useRadius,
      keyword,
      kategori: queryParams.kategori,
      skillId: queryParams.skill_id,
      tipePenawaran: queryParams.tipe_penawaran,
      minHarga: queryParams.min_harga,
      maxHarga: queryParams.max_harga,
      minRating: queryParams.min_rating,
      penyediaId: queryParams.penyedia_id,
      sortBy: queryParams.sort_by || 'jarak',
      limit,
      offset,
    });

    return {
      items,
      meta: {
        titik_acuan: { lat, lng },
        radius_meter: useRadius ? radiusMeters : null,
        use_radius: useRadius,
        sort_by: queryParams.sort_by || 'jarak',
        page,
        limit,
        total_loaded: items.length,
      },
    };
  }

  async getMyGigs(userId) {
    return listingsRepository.findByOwner(userId);
  }

  async getGigDetail(listingId, currentUser = null) {
    const gig = await listingsRepository.findById(listingId, {
      lat: env.hyperlocal.defaultLat,
      lng: env.hyperlocal.defaultLng,
    });

    if (!gig) {
      throw new AppError('Gig / listing jasa tidak ditemukan.', 404, 'GIG_NOT_FOUND');
    }

    // FR-20: Listing nonaktif atau disembunyikan hanya bisa dilihat oleh pemilik atau Admin
    const isOwner = currentUser && currentUser.user_id === gig.penyedia_id;
    const isAdmin = currentUser && currentUser.peran === 'Administrator';
    if (gig.status !== 'Aktif' && !isOwner && !isAdmin) {
      throw new AppError(
        'Gig / listing jasa tidak ditemukan atau sedang tidak aktif.',
        404,
        'GIG_NOT_FOUND'
      );
    }

    return gig;
  }

  async createGig(userId, payload) {
    const skill = await listingsRepository.resolveSkillId({
      skillId: payload.skill_id,
      kategori: payload.kategori,
    });

    if (!skill) {
      throw new AppError(
        'Kategori atau skill_id yang dipilih tidak valid. Gunakan endpoint GET /api/v1/gigs/categories untuk melihat daftar kategori yang tersedia.',
        400,
        'INVALID_CATEGORY_OR_SKILL'
      );
    }

    const created = await listingsRepository.create({
      penyediaId: userId,
      skillId: skill.skill_id,
      judul: payload.judul,
      deskripsi: payload.deskripsi,
      harga: payload.harga,
      latitude: payload.latitude,
      longitude: payload.longitude,
      tipePenawaran: payload.tipe_penawaran || 'Berbayar',
      deskripsiImbalanBarter: payload.deskripsi_imbalan_barter,
      status: payload.status || 'Aktif',
    });

    await listingsRepository.writeAuditLog({
      aktorId: userId,
      aksi: 'CREATE_GIG',
      objekId: created.listing_id,
      statusSebelum: null,
      statusSesudah: created.status,
    });

    return created;
  }

  async updateGig(listingId, userId, payload) {
    const existing = await listingsRepository.findById(listingId);
    if (!existing) {
      throw new AppError('Gig / listing jasa tidak ditemukan.', 404, 'GIG_NOT_FOUND');
    }

    // ACCEPTANCE CRITERIA: Pengguna tidak dapat mengubah gigs milik orang lain (FR-07, NFR-08)
    if (existing.penyedia_id !== userId) {
      throw new AppError(
        'Anda tidak memiliki hak akses untuk mengubah gig milik pengguna lain.',
        403,
        'FORBIDDEN_NOT_OWNER'
      );
    }

    if (existing.status === 'Disembunyikan Moderasi' && payload.status) {
      throw new AppError(
        'Gig ini sedang disembunyikan oleh Administrator dan tidak dapat diaktifkan secara sepihak.',
        403,
        'GIG_MODERATED'
      );
    }

    let resolvedSkillId;
    if (payload.skill_id !== undefined || payload.kategori !== undefined) {
      const skill = await listingsRepository.resolveSkillId({
        skillId: payload.skill_id,
        kategori: payload.kategori,
      });
      if (!skill) {
        throw new AppError(
          'Kategori atau skill_id yang dipilih tidak valid.',
          400,
          'INVALID_CATEGORY_OR_SKILL'
        );
      }
      resolvedSkillId = skill.skill_id;
    }

    const finalOfferType = payload.tipe_penawaran || existing.tipe_penawaran;
    const finalBarterDesc =
      payload.deskripsi_imbalan_barter !== undefined
        ? payload.deskripsi_imbalan_barter
        : existing.deskripsi_imbalan_barter;

    if (
      (finalOfferType === 'Barter' || finalOfferType === 'Berbayar dan Barter') &&
      (!finalBarterDesc || finalBarterDesc.trim().length < 5)
    ) {
      throw new AppError(
        'Untuk penawaran Barter, deskripsi_imbalan_barter wajib diisi (minimal 5 karakter).',
        422,
        'VALIDATION_ERROR'
      );
    }

    const latitude = payload.latitude !== undefined ? payload.latitude : existing.latitude;
    const longitude = payload.longitude !== undefined ? payload.longitude : existing.longitude;

    const updated = await listingsRepository.update(listingId, {
      skillId: resolvedSkillId,
      judul: payload.judul,
      deskripsi: payload.deskripsi,
      harga: payload.harga,
      latitude: payload.latitude !== undefined || payload.longitude !== undefined ? latitude : undefined,
      longitude: payload.latitude !== undefined || payload.longitude !== undefined ? longitude : undefined,
      tipePenawaran: payload.tipe_penawaran,
      deskripsiImbalanBarter: payload.deskripsi_imbalan_barter,
      status: payload.status,
    });

    await listingsRepository.writeAuditLog({
      aktorId: userId,
      aksi: 'UPDATE_GIG',
      objekId: listingId,
      statusSebelum: existing.status,
      statusSesudah: updated.status,
    });

    return updated;
  }

  async deleteGig(listingId, userId) {
    const existing = await listingsRepository.findById(listingId);
    if (!existing) {
      throw new AppError('Gig / listing jasa tidak ditemukan.', 404, 'GIG_NOT_FOUND');
    }

    // Validasi pemilik (FR-07, Kerjaan #4)
    if (existing.penyedia_id !== userId) {
      throw new AppError(
        'Anda tidak memiliki hak akses untuk menghapus gig milik pengguna lain.',
        403,
        'FORBIDDEN_NOT_OWNER'
      );
    }

    // FR-21: Cegah penghapusan permanen listing yang masih terkait pesanan/barter aktif
    const isBusy = await listingsRepository.hasActiveTransactions(listingId);
    if (isBusy) {
      throw new AppError(
        'Gig tidak dapat dihapus permanen karena masih memiliki pesanan atau kesepakatan barter yang belum selesai. Silakan ubah status gig menjadi Nonaktif.',
        400,
        'GIG_HAS_ACTIVE_TRANSACTIONS'
      );
    }

    await listingsRepository.deleteById(listingId);
    await listingsRepository.writeAuditLog({
      aktorId: userId,
      aksi: 'DELETE_GIG',
      objekId: listingId,
      statusSebelum: existing.status,
      statusSesudah: 'DELETED',
    });
  }

  async moderateGig(listingId, { status, alasan }, adminId) {
    const existing = await listingsRepository.findById(listingId);
    if (!existing) {
      throw new AppError('Gig / listing jasa tidak ditemukan.', 404, 'GIG_NOT_FOUND');
    }

    const updated = await listingsRepository.update(listingId, { status });
    await listingsRepository.writeAuditLog({
      aktorId: adminId,
      aksi: `MODERATE_GIG: ${alasan}`,
      objekId: listingId,
      statusSebelum: existing.status,
      statusSesudah: status,
    });
    return updated;
  }
}

module.exports = new ListingsService();
