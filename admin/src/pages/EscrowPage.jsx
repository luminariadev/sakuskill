import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import {
  Wallet,
  ShieldCheck,
  Download,
  Filter,
  ArrowUpRight,
  ArrowDownLeft,
  FileSpreadsheet,
  CheckCircle2,
  Clock,
  RefreshCw,
  Search,
} from 'lucide-react';

export function EscrowPage({ escrowData }) {
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [searchQuery, setSearchQuery] = useState('');
  const [downloadSuccess, setDownloadSuccess] = useState(false);

  const saldoLive = escrowData?.saldo_penampungan_live || 'Rp 4.250.000';
  const transactions = escrowData?.transaksi || [
    {
      id: 'SK-2024-091',
      jenis: 'Escrow Berbayar',
      pihak: 'Dimas Arya (Klien) -> Salma Nur Oktavia (Penyedia)',
      nominal: 'Rp 50.000',
      status_escrow: 'Ditahan Simulasi (Escrow)',
      status_pesanan: 'Pengerjaan Berjalan',
      tanggal: '17 Nov 2026',
    },
    {
      id: 'SK-2024-058',
      jenis: 'Escrow Berbayar',
      pihak: 'Ahmad Fauzi (Klien) -> Rizkia (Penyedia)',
      nominal: 'Rp 45.000',
      status_escrow: 'Dilepas Simulasi',
      status_pesanan: 'Selesai',
      tanggal: '16 Nov 2026',
    },
    {
      id: 'BTR-2024-012',
      jenis: 'Smart Barter Non-Tunai',
      pihak: 'Salsa (Pihak 1) <-> Rizkia (Pihak 2)',
      nominal: 'Non-Tunai',
      status_escrow: 'Smart Barter Aktif',
      status_pesanan: 'Pengerjaan Bersama',
      tanggal: '17 Nov 2026',
    },
    {
      id: 'DS-2024-004',
      jenis: 'Sengketa Escrow',
      pihak: 'Dimas Arya vs Salma Nur Oktavia',
      nominal: 'Rp 50.000',
      status_escrow: 'Dibekukan (Sengketa)',
      status_pesanan: 'Menunggu Eksekusi 50:50',
      tanggal: '17 Nov 2026',
    },
  ];

  const filters = [
    'Semua',
    'Dana Ditahan',
    'Pengerjaan Berjalan',
    'Dalam Sengketa',
    'Dana Dilepas/Selesai',
  ];

  const filtered = transactions.filter((t) => {
    if (activeFilter === 'Dana Ditahan' && !t.status_escrow?.includes('Ditahan')) return false;
    if (activeFilter === 'Pengerjaan Berjalan' && !t.status_pesanan?.includes('Berjalan') && !t.status_pesanan?.includes('Bersama')) return false;
    if (activeFilter === 'Dalam Sengketa' && !t.status_escrow?.includes('Sengketa') && !t.status_escrow?.includes('Beku')) return false;
    if (activeFilter === 'Dana Dilepas/Selesai' && !t.status_escrow?.includes('Dilepas') && !t.status_pesanan?.includes('Selesai')) return false;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchId = t.id?.toLowerCase().includes(q);
      const matchParty = t.pihak?.toLowerCase().includes(q);
      const matchType = t.jenis?.toLowerCase().includes(q);
      if (!matchId && !matchParty && !matchType) return false;
    }
    return true;
  });

  const handleDownloadCsv = () => {
    const headers = ['ID Transaksi', 'Jenis', 'Pihak Terlibat', 'Nominal', 'Status Escrow', 'Status Pesanan', 'Tanggal'];
    const rows = transactions.map((t) => [
      t.id,
      t.jenis,
      `"${t.pihak}"`,
      t.nominal,
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
    link.setAttribute('download', `Audit_Escrow_SakuSkill_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setDownloadSuccess(true);
    setTimeout(() => setDownloadSuccess(false), 3000);
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
          <Wallet className="w-6 h-6 text-emerald-400" />
          <span>Monitoring Transaksi & Rekening Penampungan (Escrow)</span>
        </h1>
        <p className="text-xs text-slate-400 mt-1">
          Pengawasan buku besar dana penampungan simulasi, audit pergerakan dana, dan pelacakan transaksi barter mahasiswa.
        </p>
      </div>

      {/* Saldo Penampungan Card (Figma Screen 7 Header) */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-emerald-950/60 via-[#111827] to-slate-900 border border-emerald-500/30 shadow-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div className="space-y-2">
          <div className="flex items-center gap-2">
            <span className="px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-400/30 flex items-center gap-1.5">
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              TERKUNCI - SIMULASI ESCROW
            </span>
            <span className="text-xs text-slate-400">PBI PJP Compliance Tier Sandbox</span>
          </div>
          <div>
            <span className="text-xs font-medium text-slate-400">Total Saldo Penampungan Aktif</span>
            <p className="text-3xl font-mono font-bold text-white tracking-tight mt-0.5">
              {saldoLive}
            </p>
          </div>
          <p className="text-xs text-slate-400 max-w-xl leading-relaxed">
            Platform kampus SakuSkill menggunakan protokol penampungan internal tersimulasi untuk menjamin keamanan
            hasil pekerjaan mahasiswa sebelum pencairan dilakukan.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-stretch gap-3 shrink-0">
          <button
            onClick={handleDownloadCsv}
            className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 transition shadow-lg shadow-emerald-950/40"
          >
            <Download className="w-4 h-4" />
            <span>Unduh Laporan Audit (CSV)</span>
          </button>
        </div>
      </div>

      {downloadSuccess && (
        <div className="p-3.5 rounded-xl bg-emerald-950/60 border border-emerald-500/40 text-xs font-bold text-emerald-300 flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          <span>Berkas audit CSV berhasil diunduh ke komputer Anda!</span>
        </div>
      )}

      {/* Filter Tabs & Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex items-center gap-1.5 p-1 rounded-xl bg-slate-900 border border-slate-800 overflow-x-auto">
          {filters.map((f) => (
            <button
              key={f}
              onClick={() => setActiveFilter(f)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition shrink-0 ${
                activeFilter === f
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              {f}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari ID transaksi, nama pihak..."
            className="w-full pl-9 pr-4 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-[#111827] border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#0B1120] text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3.5 px-6">ID Referensi</th>
                <th className="py-3.5 px-4">Jenis Transaksi</th>
                <th className="py-3.5 px-4">Pihak Terlibat</th>
                <th className="py-3.5 px-4">Nominal Nilai</th>
                <th className="py-3.5 px-4">Status Penampungan</th>
                <th className="py-3.5 px-4">Status Siklus Pesanan</th>
                <th className="py-3.5 px-6 text-right">Tanggal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 font-sans">
              {filtered.map((t) => (
                <tr key={t.id} className="hover:bg-slate-850/50 transition">
                  <td className="py-4 px-6 font-mono font-bold text-emerald-400">{t.id}</td>
                  <td className="py-4 px-4 font-semibold text-slate-200">{t.jenis}</td>
                  <td className="py-4 px-4 text-slate-300 font-medium max-w-xs truncate">{t.pihak}</td>
                  <td className="py-4 px-4 font-mono font-bold text-white">{t.nominal}</td>
                  <td className="py-4 px-4">
                    <StatusBadge status={t.status_escrow} />
                  </td>
                  <td className="py-4 px-4">
                    <StatusBadge status={t.status_pesanan} />
                  </td>
                  <td className="py-4 px-6 text-right text-slate-400 font-mono text-[11px]">
                    {t.tanggal}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
