import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { GigModerationModal } from '../components/GigModerationModal';
import {
  Search,
  Filter,
  ShieldAlert,
  AlertOctagon,
  Star,
  Eye,
  CheckCircle,
  AlertTriangle,
} from 'lucide-react';

export function ServicesPage({ listings = [], onModerateListing }) {
  const [activeCategory, setActiveCategory] = useState('Semua');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedGigForModeration, setSelectedGigForModeration] = useState(null);

  const categories = [
    'Semua',
    'Desain & Grafis',
    'Coding & Web',
    'Penulisan & Terjemahan',
    'Multimedia',
    'Jasa Kampus',
  ];

  const filteredListings = listings.filter((gig) => {
    if (activeCategory !== 'Semua' && gig.kategori !== activeCategory) {
      return false;
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchTitle = gig.judul?.toLowerCase().includes(q);
      const matchProvider = gig.penyedia_nama?.toLowerCase().includes(q);
      const matchId = String(gig.listing_id || '').toLowerCase().includes(q);
      if (!matchTitle && !matchProvider && !matchId) return false;
    }
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <h1 className="text-2xl font-bold text-white tracking-tight">Manajemen Layanan & Kebijakan Anti-Joki</h1>
        <p className="text-xs text-slate-400 mt-1">
          Kurasi listing keterampilan mahasiswa UPI Cibiru, pencegahan joki akademik, dan perlindungan reputasi kampus.
        </p>
      </div>

      {/* Category Pills & Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex items-center gap-1.5 p-1 rounded-xl bg-slate-900 border border-slate-800 overflow-x-auto">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition shrink-0 ${
                activeCategory === cat
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari judul gig atau penyedia..."
            className="w-full pl-9 pr-4 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition"
          />
        </div>
      </div>

      {/* Services Table */}
      <div className="bg-[#111827] border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#0B1120] text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3.5 px-6">ID & Judul Layanan (Gig)</th>
                <th className="py-3.5 px-4">Penyedia Mahasiswa</th>
                <th className="py-3.5 px-4">Kategori Keahlian</th>
                <th className="py-3.5 px-4">Harga Patokan</th>
                <th className="py-3.5 px-4">Rating & Ulasan</th>
                <th className="py-3.5 px-4">Status Kurasi</th>
                <th className="py-3.5 px-6 text-right">Moderasi Etika</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {filteredListings.map((gig) => {
                const isViolating =
                  gig.status?.toLowerCase().includes('joki') ||
                  gig.indikasi_pelanggaran ||
                  gig.judul?.toLowerCase().includes('joki') ||
                  gig.judul?.toLowerCase().includes('skripsi kilat');

                return (
                  <tr
                    key={gig.listing_id}
                    className={`transition ${
                      isViolating
                        ? 'bg-rose-950/20 hover:bg-rose-950/30 border-l-4 border-l-rose-500'
                        : 'hover:bg-slate-850/50'
                    }`}
                  >
                    {/* Judul & ID */}
                    <td className="py-4 px-6 max-w-sm">
                      <div className="flex items-start gap-2">
                        {isViolating && (
                          <AlertOctagon className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                        )}
                        <div>
                          <p className="font-semibold text-white text-xs leading-snug">{gig.judul}</p>
                          <span className="font-mono text-[10px] text-slate-400">
                            ID: #{String(gig.listing_id).slice(0, 8)}
                          </span>
                          {isViolating && (
                            <p className="text-[10px] text-rose-400 font-medium mt-1">
                              Terdeteksi: Pelanggaran Integritas Akademik
                            </p>
                          )}
                        </div>
                      </div>
                    </td>

                    {/* Penyedia */}
                    <td className="py-4 px-4">
                      <p className="font-medium text-slate-200">{gig.penyedia_nama}</p>
                    </td>

                    {/* Kategori */}
                    <td className="py-4 px-4">
                      <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-slate-800 text-slate-300 border border-slate-700">
                        {gig.kategori}
                      </span>
                    </td>

                    {/* Harga */}
                    <td className="py-4 px-4 font-mono font-bold text-emerald-400">
                      {gig.harga > 0 ? `Rp ${gig.harga.toLocaleString('id-ID')}` : 'Barter / Gratis'}
                    </td>

                    {/* Rating */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-1 text-amber-400 font-bold">
                        <Star className="w-3.5 h-3.5 fill-current" />
                        <span>{gig.rating}</span>
                        <span className="text-slate-400 text-[10px] font-normal">({gig.ulasan_count || 12})</span>
                      </div>
                    </td>

                    {/* Status */}
                    <td className="py-4 px-4">
                      <StatusBadge
                        status={gig.status}
                        tone={isViolating ? 'danger' : 'success'}
                      />
                    </td>

                    {/* Aksi Moderasi */}
                    <td className="py-4 px-6 text-right">
                      <button
                        onClick={() => setSelectedGigForModeration(gig)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ml-auto ${
                          isViolating
                            ? 'bg-rose-600 hover:bg-rose-500 text-white shadow-sm shadow-rose-950/40'
                            : 'bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white'
                        }`}
                      >
                        <ShieldAlert className="w-3.5 h-3.5" />
                        <span>{isViolating ? 'Takedown Joki' : 'Tindakan'}</span>
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Moderation Modal */}
      <GigModerationModal
        isOpen={!!selectedGigForModeration}
        onClose={() => setSelectedGigForModeration(null)}
        gig={selectedGigForModeration}
        onModerate={onModerateListing}
      />
    </div>
  );
}
