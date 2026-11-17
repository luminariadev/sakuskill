import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { KtmModal } from '../components/KtmModal';
import { SanctionModal } from '../components/SanctionModal';
import {
  Search,
  Filter,
  CheckCircle2,
  ShieldAlert,
  GraduationCap,
  Star,
  ExternalLink,
  Eye,
  AlertTriangle,
} from 'lucide-react';

export function UsersPage({ users = [], onVerifyUser, onSanctionUser }) {
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUserForKtm, setSelectedUserForKtm] = useState(null);
  const [selectedUserForSanction, setSelectedUserForSanction] = useState(null);

  const filters = [
    { id: 'Semua', label: 'Semua Mahasiswa' },
    { id: 'Terverifikasi', label: 'Terverifikasi KTM' },
    { id: 'Menunggu', label: 'Menunggu Verifikasi' },
    { id: 'Dibekukan', label: 'Dibekukan / Bermasalah' },
  ];

  const filteredUsers = users.filter((u) => {
    // Filter tab
    if (activeFilter === 'Terverifikasi' && u.status_verifikasi !== 'Terverifikasi') return false;
    if (activeFilter === 'Menunggu' && u.status_verifikasi !== 'Menunggu Verifikasi') return false;
    if (activeFilter === 'Dibekukan' && !u.status_akun?.toLowerCase().includes('beku') && !u.status_akun?.toLowerCase().includes('lapor')) return false;

    // Search query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchName = u.nama?.toLowerCase().includes(q);
      const matchNim = u.nim?.toLowerCase().includes(q);
      const matchEmail = u.email?.toLowerCase().includes(q);
      const matchProdi = u.program_studi?.toLowerCase().includes(q);
      if (!matchName && !matchNim && !matchEmail && !matchProdi) return false;
    }
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Title */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Manajemen Pengguna & Verifikasi Mahasiswa</h1>
          <p className="text-xs text-slate-400 mt-1">
            Validasi KTM mahasiswa UPI Cibiru, pantau reputasi pengguna, dan penegakan tata tertib platform.
          </p>
        </div>
      </div>

      {/* Filter Tabs & Search Bar */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        {/* Tabs */}
        <div className="flex items-center gap-1.5 p-1 rounded-xl bg-slate-900 border border-slate-800 overflow-x-auto">
          {filters.map((f) => (
            <button
              key={f.id}
              onClick={() => setActiveFilter(f.id)}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition shrink-0 ${
                activeFilter === f.id
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Search Input */}
        <div className="relative w-full sm:w-72">
          <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari nama, NIM, prodi..."
            className="w-full pl-9 pr-4 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition"
          />
        </div>
      </div>

      {/* Table Card */}
      <div className="bg-[#111827] border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#0B1120] text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3.5 px-6">Identitas Mahasiswa</th>
                <th className="py-3.5 px-4">NIM & Program Studi</th>
                <th className="py-3.5 px-4">Status Verifikasi</th>
                <th className="py-3.5 px-4">Status Akun</th>
                <th className="py-3.5 px-4">Transaksi & Rating</th>
                <th className="py-3.5 px-6 text-right">Tindakan Administrator</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-500 text-xs">
                    Tidak ada data mahasiswa yang sesuai dengan filter pencarian.
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.user_id} className="hover:bg-slate-850/50 transition">
                    {/* Mahasiswa */}
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-xs text-emerald-400 shrink-0 overflow-hidden">
                          {user.foto_ktm_url ? (
                            <img src={user.foto_ktm_url} alt={user.nama} className="w-full h-full object-cover" />
                          ) : (
                            user.nama?.charAt(0) || 'U'
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="font-semibold text-white truncate text-xs">{user.nama}</p>
                          <p className="text-[11px] text-slate-400 truncate">{user.email}</p>
                        </div>
                      </div>
                    </td>

                    {/* NIM & Prodi */}
                    <td className="py-4 px-4">
                      <p className="font-mono font-bold text-emerald-400">{user.nim || '2201948'}</p>
                      <p className="text-slate-300 text-[11px] mt-0.5">{user.program_studi || 'Pendidikan Multimedia'}</p>
                    </td>

                    {/* Status Verifikasi */}
                    <td className="py-4 px-4">
                      <StatusBadge status={user.status_verifikasi} />
                    </td>

                    {/* Status Akun */}
                    <td className="py-4 px-4">
                      <StatusBadge status={user.status_akun} />
                    </td>

                    {/* Transaksi & Rating */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-3">
                        <div>
                          <span className="text-[10px] text-slate-400">Order</span>
                          <p className="font-bold text-white">{user.jumlah_transaksi ?? 0}</p>
                        </div>
                        {user.rating > 0 && (
                          <div className="flex items-center gap-1 text-amber-400 font-bold">
                            <Star className="w-3.5 h-3.5 fill-current" />
                            <span>{user.rating}</span>
                          </div>
                        )}
                      </div>
                    </td>

                    {/* Aksi */}
                    <td className="py-4 px-6 text-right space-x-2">
                      {user.status_verifikasi === 'Menunggu Verifikasi' && (
                        <button
                          onClick={() => setSelectedUserForKtm(user)}
                          className="px-3 py-1.5 rounded-lg text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 transition shadow-sm"
                        >
                          Tinjau KTM
                        </button>
                      )}
                      <button
                        onClick={() => setSelectedUserForKtm(user)}
                        title="Inspeksi Berkas KTM"
                        className="px-2.5 py-1.5 rounded-lg text-xs font-medium text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 transition"
                      >
                        <Eye className="w-3.5 h-3.5 inline mr-1" />
                        KTM
                      </button>
                      <button
                        onClick={() => setSelectedUserForSanction(user)}
                        title="Sanksi Akun"
                        className="px-2.5 py-1.5 rounded-lg text-xs font-semibold text-rose-300 hover:text-white bg-rose-950/60 hover:bg-rose-900 border border-rose-800/40 transition"
                      >
                        <ShieldAlert className="w-3.5 h-3.5 inline mr-1" />
                        Sanksi
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modals */}
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
