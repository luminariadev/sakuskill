import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { Wallet, ShieldCheck, Download, Search, CheckCircle2 } from 'lucide-react';

export function EscrowPage({ escrowData }) {
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [searchQuery, setSearchQuery] = useState('');
  const [downloadSuccess, setDownloadSuccess] = useState(false);

  const saldoLive = escrowData?.saldo_penampungan_live || 'Rp 0';
  const saldoDilepas = escrowData?.saldo_dilepas_total || 'Rp 0';
  const orderCount = escrowData?.jumlah_order ?? 0;
  const barterCount = escrowData?.jumlah_barter ?? 0;
  const transactions = escrowData?.transaksi || [];

  const filters = [
    'Semua',
    'Escrow Berbayar',
    'Smart Barter Rp 0',
    'Ditahan',
    'Selesai',
  ];

  const filtered = transactions.filter((t) => {
    if (activeFilter === 'Escrow Berbayar' && t.jenis !== 'Escrow Berbayar') return false;
    if (activeFilter === 'Smart Barter Rp 0' && t.jenis !== 'Smart Barter Rp 0') return false;
    if (
      activeFilter === 'Ditahan' &&
      !t.status_escrow?.toLowerCase().includes('ditahan') &&
      !t.status_escrow?.toLowerCase().includes('beku')
    ) {
      return false;
    }
    if (
      activeFilter === 'Selesai' &&
      !t.status_pesanan?.toLowerCase().includes('selesai') &&
      !t.status_escrow?.toLowerCase().includes('dilepas') &&
      !t.status_escrow?.toLowerCase().includes('tuntas')
    ) {
      return false;
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const hay = [t.id, t.judul, t.pihak, t.jenis, t.referensi]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });

  const handleDownloadCsv = () => {
    const headers = [
      'ID Transaksi',
      'Jenis',
      'Layanan',
      'Pihak Terlibat',
      'Nominal',
      'Referensi',
      'Status Escrow',
      'Status Transaksi',
      'Tanggal',
    ];
    const rows = transactions.map((t) => [
      t.id,
      t.jenis,
      `"${String(t.judul || '').replace(/"/g, '""')}"`,
      `"${String(t.pihak || '').replace(/"/g, '""')}"`,
      t.nominal,
      t.referensi,
      t.status_escrow,
      t.status_pesanan,
      t.tanggal,
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute(
      'download',
      `Audit_Escrow_Barter_SakuSkill_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setDownloadSuccess(true);
    setTimeout(() => setDownloadSuccess(false), 3000);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight flex items-center gap-2.5">
          <Wallet className="w-6 h-6 text-[#059669]" />
          <span>Monitoring Transaksi Escrow & Smart Barter</span>
        </h1>
        <p className="text-xs text-[#64748B] mt-1">
          Buku besar real-time seluruh pesanan berbayar simulasi dan kontrak barter Rp 0 yang dibuat dari aplikasi mobile.
        </p>
      </div>

      {/* Signature Emerald Hero Card (Matching Mobile WalletPage) */}
      <div className="hero-emerald-card p-6 md:p-7 text-white relative overflow-hidden">
        <div className="absolute -right-12 -top-12 w-56 h-56 rounded-full bg-emerald-400/15 blur-2xl pointer-events-none"></div>
        <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6 relative z-10">
          <div className="space-y-4 flex-1">
            <div className="flex items-center gap-2.5 flex-wrap">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold bg-white/10 border border-emerald-300/30 text-emerald-200">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-300" />
                <span>{escrowData?.badge_status || 'SIMULASI ESCROW & BARTER'}</span>
              </span>
            </div>

            <div>
              <span className="text-xs font-semibold text-emerald-200/80 uppercase tracking-wider">
                Total Dana Ditahan Escrow Saat Ini
              </span>
              <p className="text-3xl md:text-4xl font-extrabold tracking-tight tabular-nums mt-1">
                {saldoLive}
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 max-w-2xl">
              <div className="rounded-2xl bg-white/10 border border-white/15 px-4 py-3">
                <span className="text-[10.5px] text-emerald-200/80 block">Total Escrow Dilepas</span>
                <span className="text-sm font-extrabold tabular-nums">{saldoDilepas}</span>
              </div>
              <div className="rounded-2xl bg-white/10 border border-white/15 px-4 py-3">
                <span className="text-[10.5px] text-emerald-200/80 block">Pesanan Berbayar</span>
                <span className="text-sm font-extrabold tabular-nums">{orderCount} Order</span>
              </div>
              <div className="rounded-2xl bg-white/10 border border-white/15 px-4 py-3">
                <span className="text-[10.5px] text-emerald-200/80 block">Smart Barter Rp 0</span>
                <span className="text-sm font-extrabold tabular-nums">{barterCount} Kontrak</span>
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={handleDownloadCsv}
            disabled={transactions.length === 0}
            className="inline-flex items-center gap-2 px-5 py-3 rounded-2xl bg-white text-[#064E3B] hover:bg-emerald-50 font-extrabold text-xs shadow-lg transition shrink-0 disabled:opacity-50"
          >
            <Download className="w-4 h-4" />
            <span>Unduh Audit Ledger (CSV)</span>
          </button>
        </div>
      </div>

      {downloadSuccess && (
        <div className="clay-card p-3.5 border-[#A7F3D0] bg-[#ECFDF5] flex items-center gap-2 text-xs text-[#065F46] font-bold">
          <CheckCircle2 className="w-4 h-4 text-[#059669]" />
          <span>File CSV laporan audit transaksi berhasil diunduh.</span>
        </div>
      )}

      {/* Filter & Search */}
      <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-4">
        <div className="flex items-center gap-1.5 p-1.5 rounded-2xl clay-tile overflow-x-auto">
          {filters.map((f) => (
            <button
              key={f}
              onClick={() => setActiveFilter(f)}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition shrink-0 ${
                activeFilter === f
                  ? 'clay-btn-primary'
                  : 'text-[#64748B] hover:text-[#0F172A] hover:bg-[#F0F4F2]'
              }`}
            >
              {f}
            </button>
          ))}
        </div>

        <div className="relative w-full lg:w-72">
          <Search className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari kode, layanan, atau pihak..."
            className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] shadow-clay-sm transition"
          />
        </div>
      </div>

      {/* Ledger Table */}
      <div className="clay-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F7FAF8] text-[#64748B] font-bold border-b border-[#E6EFEA] uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3 px-3.5">Kode</th>
                <th className="py-3 px-3">Jenis & Layanan</th>
                <th className="py-3 px-3">Pihak Terlibat</th>
                <th className="py-3 px-3">Nominal</th>
                <th className="py-3 px-3">Status Escrow</th>
                <th className="py-3 px-3">Status Transaksi</th>
                <th className="py-3 px-3.5 text-right">Pembaruan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#EEF3F0]">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-[#64748B] text-xs">
                    Belum ada transaksi pesanan atau Smart Barter yang cocok dengan filter ini.
                  </td>
                </tr>
              ) : (
                filtered.map((row) => (
                  <tr key={`${row.id}-${row.raw_id}`} className="hover:bg-[#F7FAF8] transition">
                    <td className="py-3.5 px-3.5 font-mono font-extrabold text-[#059669] whitespace-nowrap">
                      {row.id}
                    </td>
                    <td className="py-3.5 px-3 max-w-[190px]">
                      <span
                        className={`inline-block px-2 py-0.5 rounded-full text-[10px] font-bold mb-1 ${
                          row.jenis.includes('Barter')
                            ? 'bg-[#F3E8FF] text-[#7E22CE]'
                            : 'bg-[#EFF6FF] text-[#2563EB]'
                        }`}
                      >
                        {row.jenis}
                      </span>
                      <p className="font-bold text-[#0F172A] truncate">{row.judul}</p>
                    </td>
                    <td className="py-3.5 px-3 font-semibold text-[#0F172A] max-w-[165px]">
                      {row.pihak}
                    </td>
                    <td className="py-3.5 px-3 font-mono font-bold text-[#0F172A] tabular-nums whitespace-nowrap">
                      {row.nominal}
                    </td>
                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <StatusBadge
                        status={row.status_escrow}
                        tone={row.jenis.includes('Barter') ? 'purple' : undefined}
                      />
                    </td>
                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <StatusBadge status={row.status_pesanan} />
                    </td>
                    <td className="py-3.5 px-3.5 text-right text-[#64748B] whitespace-nowrap">
                      {row.tanggal}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
