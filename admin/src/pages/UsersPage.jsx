import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { KtmModal } from '../components/KtmModal';
import { SanctionModal } from '../components/SanctionModal';
import { UserAvatar } from '../components/UserAvatar';
import { Search, ShieldAlert, Star, Eye } from 'lucide-react';

export function UsersPage({ users = [], onVerifyUser, onSanctionUser }) {
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUserForKtm, setSelectedUserForKtm] = useState(null);
  const [selectedUserForSanction, setSelectedUserForSanction] = useState(null);

  const filters = [
    { id: 'Semua', label: `Semua (${users.length})` },
    {
      id: 'Terverifikasi',
      label: `Terverifikasi (${users.filter((u) => u.status_verifikasi === 'Terverifikasi').length})`,
    },
    {
      id: 'Belum Terverifikasi',
      label: `Menunggu Verifikasi (${users.filter((u) => u.status_verifikasi === 'Belum Terverifikasi').length})`,
    },
    {
      id: 'Bermasalah',
      label: `Ditolak / Disanksi (${
        users.filter(
          (u) =>
            u.status_verifikasi === 'Ditolak' ||
            (u.status_akun && u.status_akun !== 'Aktif')
        ).length
      })`,
    },
  ];

  const filteredUsers = users.filter((u) => {
    if (activeFilter === 'Terverifikasi' && u.status_verifikasi !== 'Terverifikasi') {
      return false;
    }
    if (
      activeFilter === 'Belum Terverifikasi' &&
      u.status_verifikasi !== 'Belum Terverifikasi'
    ) {
      return false;
    }
    if (
      activeFilter === 'Bermasalah' &&
      u.status_verifikasi !== 'Ditolak' &&
      (!u.status_akun || u.status_akun === 'Aktif')
    ) {
      return false;
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const hay = [u.nama, u.email, u.peran, u.deskripsi_profil]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight">
          Manajemen Pengguna & Verifikasi
        </h1>
        <p className="text-xs text-[#64748B] mt-1">
          Data akun dan foto profil sinkron langsung dengan aplikasi mobile (UIN Sunan Gunung Djati Bandung).
        </p>
      </div>

      <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-4">
        <div className="flex items-center gap-1.5 p-1.5 rounded-2xl clay-tile overflow-x-auto">
          {filters.map((f) => (
            <button
              key={f.id}
              onClick={() => setActiveFilter(f.id)}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition shrink-0 ${
                activeFilter === f.id
                  ? 'clay-btn-primary'
                  : 'text-[#64748B] hover:text-[#0F172A] hover:bg-[#F0F4F2]'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        <div className="relative w-full lg:w-80">
          <Search className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari nama, email, bio profil..."
            className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] shadow-clay-sm transition"
          />
        </div>
      </div>

      <div className="clay-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F7FAF8] text-[#64748B] font-bold border-b border-[#E6EFEA] uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3 px-4">Pengguna (Foto & Bio)</th>
                <th className="py-3 px-3">Peran</th>
                <th className="py-3 px-3">Verifikasi</th>
                <th className="py-3 px-3">Status Akun</th>
                <th className="py-3 px-3">Aktivitas & Rating</th>
                <th className="py-3 px-4 text-right">Tindakan Admin</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#EEF3F0]">
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-[#64748B] text-xs">
                    Tidak ada data pengguna yang sesuai filter saat ini.
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.user_id} className="hover:bg-[#F7FAF8] transition">
                    <td className="py-3.5 px-4 max-w-[260px]">
                      <div className="flex items-center gap-3">
                        <UserAvatar
                          name={user.nama}
                          photoUrl={user.foto_profil}
                          sizeClass="w-10 h-10 text-xs"
                        />
                        <div className="min-w-0">
                          <p className="font-bold text-[#0F172A] truncate text-xs">{user.nama}</p>
                          <p className="text-[11px] text-[#64748B] font-mono truncate">{user.email}</p>
                          {user.deskripsi_profil && (
                            <p className="text-[11px] text-[#475569] truncate mt-0.5">
                              {user.deskripsi_profil}
                            </p>
                          )}
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-[#F0F4F2] text-[#0F172A] border border-[#DCE5E0]">
                        {user.peran}
                      </span>
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <StatusBadge status={user.status_verifikasi} />
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <StatusBadge status={user.status_akun || 'Aktif'} />
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <div className="flex items-center gap-2.5 tabular-nums">
                        <div>
                          <span className="text-[10px] text-[#64748B] block">Transaksi / Jasa</span>
                          <p className="font-bold text-[#0F172A]">
                            {user.jumlah_transaksi ?? 0} trx · {user.jumlah_layanan ?? 0} gig
                          </p>
                        </div>
                        {Number(user.rating) > 0 && (
                          <div className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#FFFBEB] border border-[#FDE68A] text-[#B45309] font-bold">
                            <Star className="w-3 h-3 fill-current" />
                            <span>{Number(user.rating).toFixed(1)}</span>
                          </div>
                        )}
                      </div>
                    </td>

                    <td className="py-3.5 px-4 text-right space-x-1.5 whitespace-nowrap">
                      <button
                        onClick={() => setSelectedUserForKtm(user)}
                        className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                          user.status_verifikasi === 'Belum Terverifikasi'
                            ? 'clay-btn-primary'
                            : 'text-[#0F172A] bg-[#F0F4F2] hover:bg-[#ECFDF5] hover:text-[#047857] border border-[#DCE5E0]'
                        }`}
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span>
                          {user.status_verifikasi === 'Belum Terverifikasi'
                            ? 'Verifikasi'
                            : 'Profil'}
                        </span>
                      </button>
                      {user.peran !== 'Administrator' && (
                        <button
                          onClick={() => setSelectedUserForSanction(user)}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-bold text-[#DC2626] bg-[#FEF2F2] hover:bg-[#FEE2E2] border border-[#FECACA] transition"
                        >
                          <ShieldAlert className="w-3.5 h-3.5" />
                          <span>Sanksi</span>
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <KtmModal
        isOpen={!!selectedUserForKtm}
        onClose={() => setSelectedUserForKtm(null)}
        user={selectedUserForKtm}
        onVerify={onVerifyUser}
      />

      <SanctionModal
        isOpen={!!selectedUserForSanction}
        onClose={() => setSelectedUserForSanction(null)}
        user={selectedUserForSanction}
        onSanction={onSanctionUser}
      />
    </div>
  );
}
