import React, { useState, useMemo } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { GigModerationModal } from '../components/GigModerationModal';
import { UserAvatar } from '../components/UserAvatar';
import { Search, ShieldAlert, AlertOctagon, Star, Lock } from 'lucide-react';

export function ServicesPage({ listings = [], onModerateListing }) {
  const [activeCategory, setActiveCategory] = useState('Semua');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedGigForModeration, setSelectedGigForModeration] = useState(null);

  const categories = useMemo(() => {
    const unique = new Set(listings.map((g) => g.kategori).filter(Boolean));
    return ['Semua', ...unique];
  }, [listings]);

  const filteredListings = listings.filter((gig) => {
    if (activeCategory !== 'Semua' && gig.kategori !== activeCategory) {
      return false;
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const hay = [gig.judul, gig.penyedia_nama, gig.kategori, gig.listing_id, gig.deskripsi_imbalan_barter]
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
          Manajemen Layanan & Kebijakan Anti-Joki
        </h1>
        <p className="text-xs text-[#64748B] mt-1">
          Kurasi layanan yang diterbitkan pengguna aplikasi mobile beserta opsi Barter & perlindungan integritas akademik.
        </p>
      </div>

      <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-4">
        <div className="flex items-center gap-1.5 p-1.5 rounded-2xl clay-tile overflow-x-auto">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition shrink-0 ${
                activeCategory === cat
                  ? 'clay-btn-primary'
                  : 'text-[#64748B] hover:text-[#0F172A] hover:bg-[#F0F4F2]'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        <div className="relative w-full lg:w-72">
          <Search className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari judul, penyedia, barter..."
            className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] shadow-clay-sm transition"
          />
        </div>
      </div>

      <div className="clay-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F7FAF8] text-[#64748B] font-bold border-b border-[#E6EFEA] uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3 px-4">Judul Layanan & Penawaran</th>
                <th className="py-3 px-3">Penyedia</th>
                <th className="py-3 px-3">Kategori & Mode</th>
                <th className="py-3 px-3">Tarif / Imbalan</th>
                <th className="py-3 px-3">Rating</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-4 text-right">Moderasi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#EEF3F0]">
              {filteredListings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-[#64748B] text-xs">
                    Belum ada layanan pada kategori/pencarian ini.
                  </td>
                </tr>
              ) : (
                filteredListings.map((gig) => {
                  const isViolating = Boolean(gig.indikasi_pelanggaran);
                  return (
                    <tr
                      key={gig.listing_id}
                      className={`transition ${
                        isViolating
                          ? 'bg-[#FEF2F2]/70 border-l-4 border-l-[#DC2626]'
                          : 'hover:bg-[#F7FAF8]'
                      }`}
                    >
                      <td className="py-3.5 px-4 max-w-[230px]">
                        <div className="flex items-start gap-2">
                          {isViolating && (
                            <AlertOctagon className="w-4 h-4 text-[#DC2626] shrink-0 mt-0.5" />
                          )}
                          <div>
                            <p className="font-bold text-[#0F172A] text-xs leading-snug">
                              {gig.judul}
                            </p>
                            <div className="flex items-center gap-2 mt-1">
                              <span className="font-mono text-[10px] text-[#64748B]">
                                #{String(gig.listing_id).slice(0, 8).toUpperCase()}
                              </span>
                              {gig.sedang_terkunci && (
                                <span className="inline-flex items-center gap-1 text-[10px] font-bold text-[#2563EB] bg-[#EFF6FF] px-2 py-0.5 rounded-full border border-[#BFDBFE]">
                                  <Lock className="w-2.5 h-2.5" />
                                  <span>Sedang Dikerjakan / Selesai</span>
                                </span>
                              )}
                            </div>
                            {isViolating && (
                              <p className="text-[10.5px] text-[#DC2626] font-bold mt-1">
                                {gig.indikasi_pelanggaran}
                              </p>
                            )}
                          </div>
                        </div>
                      </td>

                      <td className="py-3.5 px-3 whitespace-nowrap">
                        <div className="flex items-center gap-2">
                          <UserAvatar
                            name={gig.penyedia_nama}
                            photoUrl={gig.penyedia_foto}
                            sizeClass="w-8 h-8 text-[10px]"
                          />
                          <span className="font-semibold text-[#0F172A]">{gig.penyedia_nama}</span>
                        </div>
                      </td>

                      <td className="py-3.5 px-3 space-y-1 whitespace-nowrap">
                        <span className="inline-block px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#F0F4F2] text-[#0F172A] border border-[#DCE5E0]">
                          {gig.kategori}
                        </span>
                        <div>
                          <span
                            className={`inline-block px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              gig.tipe_penawaran === 'Barter'
                                ? 'bg-[#F3E8FF] text-[#7E22CE]'
                                : gig.tipe_penawaran === 'Berbayar dan Barter'
                                ? 'bg-[#ECFDF5] text-[#047857]'
                                : 'bg-[#EFF6FF] text-[#2563EB]'
                            }`}
                          >
                            {gig.tipe_penawaran}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-3 tabular-nums">
                        <p className="font-mono font-bold text-[#059669]">
                          {gig.harga > 0 ? `Rp ${gig.harga.toLocaleString('id-ID')}` : 'Barter Rp 0'}
                        </p>
                        {gig.deskripsi_imbalan_barter && (
                          <p className="text-[10.5px] text-[#7E22CE] font-medium truncate max-w-[140px]">
                            Dicari: {gig.deskripsi_imbalan_barter}
                          </p>
                        )}
                      </td>

                      <td className="py-3.5 px-3 whitespace-nowrap">
                        {Number(gig.ulasan_count) > 0 ? (
                          <div className="inline-flex items-center gap-1 text-[#B45309] font-bold">
                            <Star className="w-3.5 h-3.5 fill-current" />
                            <span>{Number(gig.rating).toFixed(1)}</span>
                            <span className="text-[#64748B] text-[10px] font-normal">
                              ({gig.ulasan_count})
                            </span>
                          </div>
                        ) : (
                          <span className="text-[11px] text-[#94A3B8]">Belum ada</span>
                        )}
                      </td>

                      <td className="py-3.5 px-3 whitespace-nowrap">
                        <StatusBadge
                          status={gig.status}
                          tone={
                            isViolating
                              ? 'danger'
                              : gig.status === 'Aktif'
                              ? 'success'
                              : 'warning'
                          }
                        />
                      </td>

                      <td className="py-3.5 px-4 text-right whitespace-nowrap">
                        <button
                          onClick={() => setSelectedGigForModeration(gig)}
                          className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                            isViolating
                              ? 'bg-[#DC2626] hover:bg-[#B91C1C] text-white'
                              : 'bg-[#F0F4F2] hover:bg-[#ECFDF5] text-[#0F172A] hover:text-[#047857] border border-[#DCE5E0]'
                          }`}
                        >
                          <ShieldAlert className="w-3.5 h-3.5" />
                          <span>{isViolating ? 'Takedown' : 'Moderasi'}</span>
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <GigModerationModal
        isOpen={!!selectedGigForModeration}
        onClose={() => setSelectedGigForModeration(null)}
        gig={selectedGigForModeration}
        onModerate={onModerateListing}
      />
    </div>
  );
}
