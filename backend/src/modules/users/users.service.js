const usersRepository = require('./users.repository');
const AppError = require('../../utils/AppError');

class UsersService {
  attachCapabilities(profile, includeEmail = true) {
    const formatted = {
      user_id: profile.user_id,
      nama: profile.nama,
      ...(includeEmail ? { email: profile.email } : {}),
      peran: profile.peran,
      status_verifikasi: profile.status_verifikasi,
      deskripsi_profil: profile.deskripsi_profil,
      foto_profil: profile.foto_profil || null,
      foto_url: profile.foto_profil || null,
      rata_rata_rating: profile.rata_rata_rating,
      jumlah_ulasan: profile.jumlah_ulasan,
      keterampilan: profile.keterampilan,
      portofolio: profile.portofolio,
      dibuat_pada: profile.dibuat_pada,
      capabilities: {
        can_buy_services: true,
        can_publish_gigs: true,
        is_admin: profile.peran === 'Administrator',
      },
    };
    return formatted;
  }

  async getMyProfile(userId) {
    const profile = await usersRepository.findFullProfileById(userId);
    if (!profile) {
      throw new AppError('Profil pengguna tidak ditemukan.', 404, 'USER_NOT_FOUND');
    }
    return this.attachCapabilities(profile, true);
  }

  async getPublicProfile(userId) {
    const profile = await usersRepository.findFullProfileById(userId);
    if (!profile) {
      throw new AppError('Profil pengguna tidak ditemukan.', 404, 'USER_NOT_FOUND');
    }
    return this.attachCapabilities(profile, false);
  }

  async updateMyProfile(userId, payload) {
    try {
      await usersRepository.updateProfile(userId, {
        nama: payload.nama,
        deskripsiProfil: payload.deskripsi_profil,
        fotoProfil: payload.foto_profil,
        skillIds: payload.skill_ids,
      });
      return await this.getMyProfile(userId);
    } catch (error) {
      if (error.code === 'INVALID_SKILL_ID') {
        throw new AppError(error.message, 400, 'INVALID_SKILL_ID');
      }
      throw error;
    }
  }

  async verifyUserAccount(targetUserId, statusVerifikasi, adminId) {
    const updated = await usersRepository.updateVerificationStatus({
      targetUserId,
      statusVerifikasi,
      adminId,
    });
    if (!updated) {
      throw new AppError('Pengguna yang akan diverifikasi tidak ditemukan.', 404, 'USER_NOT_FOUND');
    }
    return updated;
  }
}

module.exports = new UsersService();
