import React from 'react';
import { KpiCard } from '../components/KpiCard';
import { StatusBadge } from '../components/StatusBadge';
import {
  Users,
  Wallet,
  AlertTriangle,
  Briefcase,
  AlertCircle,
  ArrowRight,
  ExternalLink,
  ShieldCheck,
  CheckCircle2,
  Clock,
} from 'lucide-react';

export function DashboardPage({ data, setActiveTab }) {
  const kpi = data?.kpi || {
    pengguna_terverifikasi: { label: 'Pengguna Terverifikasi (KTM)', value: 1284, subtext: '+12% mgu ini', trend: 'up' },
    transaksi_aktif_escrow: { label: 'Transaksi Aktif (Escrow)', value: 'Rp 18.450.000', subtext: '42 pesanan', trend: 'neutral' },
    laporan_dan_sengketa: { label: 'Laporan & Sengketa', value: '3 Perkara', subtext: '1 mediasi terbuka', trend: 'danger' },
    layanan_terdaftar: { label: 'Layanan Terdaftar', value: 356, subtext: '98% lolos kurasi', trend: 'up' },
  };

  const slaAlert = data?.sla_alert;
  const activities = data?.aktivitas_terbaru || [];

  return (
    <div className="space-y-8">
      {/* Page Title & Subtitle */}
      <div>
        <h1 className="text-2xl font-bold text-white tracking-tight">Dasbor Operasional Kampus</h1>
        <p className="text-xs text-slate-400 mt-1">
          Pantauan real-time aktivitas transaksi, verifikasi identitas mahasiswa UPI Cibiru, dan mediasi sengketa.
        </p>
      </div>

      {/* SLA Alert Banner (Figma Spec 178-349) */}
      {slaAlert && (
        <div className="p-5 rounded-2xl bg-gradient-to-r from-rose-950/70 via-slate-900 to-amber-950/40 border border-rose-600/50 shadow-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-rose-600/20 border border-rose-500/40 flex items-center justify-center text-rose-400 shrink-0 mt-0.5">
              <AlertCircle className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold uppercase tracking-wider text-rose-400 bg-rose-950 px-2 py-0.5 rounded border border-rose-800">
                  {slaAlert.status || 'Melebihi SLA 24 Jam'}
                </span>
                <span className="text-xs font-mono text-slate-400">Kasus #{slaAlert.case_id}</span>
              </div>
              <h4 className="text-sm font-bold text-white mt-1">{slaAlert.title}</h4>
              <p className="text-xs text-slate-300 mt-0.5 leading-relaxed max-w-3xl">
                {slaAlert.message}
              </p>
            </div>
          </div>
          <button
            onClick={() => setActiveTab('disputes')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold transition shrink-0 shadow-lg shadow-rose-950/40"
          >
            <span>Buka Sidang Mediasi</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* 4 KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <KpiCard
          title={kpi.pengguna_terverifikasi.label}
          value={kpi.pengguna_terverifikasi.value.toLocaleString('id-ID')}
          subtext={kpi.pengguna_terverifikasi.subtext}
          trend={kpi.pengguna_terverifikasi.trend}
          icon={Users}
        />
        <KpiCard
          title={kpi.transaksi_aktif_escrow.label}
          value={kpi.transaksi_aktif_escrow.value}
          subtext={kpi.transaksi_aktif_escrow.subtext}
          trend={kpi.transaksi_aktif_escrow.trend}
          icon={Wallet}
        />
        <KpiCard
          title={kpi.laporan_dan_sengketa.label}
          value={kpi.laporan_dan_sengketa.value}
          subtext={kpi.laporan_dan_sengketa.subtext}
          trend={kpi.laporan_dan_sengketa.trend}
          icon={AlertTriangle}
        />
        <KpiCard
          title={kpi.layanan_terdaftar.label}
          value={kpi.layanan_terdaftar.value.toLocaleString('id-ID')}
          subtext={kpi.layanan_terdaftar.subtext}
          trend={kpi.layanan_terdaftar.trend}
          icon={Briefcase}
        />
      </div>

      {/* Recent Activity Table */}
      <div className="bg-[#111827] border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
        <div className="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-white tracking-wide">Log Aktivitas Operasional Terbaru</h3>
            <p className="text-xs text-slate-400 mt-0.5">Peristiwa dan eskalasi transaksi terkini dalam sistem</p>
          </div>
          <span className="text-xs font-medium text-emerald-400 flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
            Real-time Feed
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#0B1120] text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3.5 px-6">ID Referensi</th>
                <th className="py-3.5 px-4">Waktu</th>
                <th className="py-3.5 px-4">Kategori</th>
                <th className="py-3.5 px-4">Pihak Terlibat</th>
                <th className="py-3.5 px-6">Keterangan Aktivitas</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-6 text-right">Aksi Cepat</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 font-sans">
              {activities.map((row) => (
                <tr key={row.id} className="hover:bg-slate-850/50 transition">
                  <td className="py-4 px-6 font-mono font-bold text-emerald-400">{row.id}</td>
                  <td className="py-4 px-4 text-slate-400 flex items-center gap-1.5 pt-4">
                    <Clock className="w-3 h-3 text-slate-400" />
                    <span>{row.waktu}</span>
                  </td>
                  <td className="py-4 px-4 font-semibold text-slate-200">{row.tipe}</td>
                  <td className="py-4 px-4 font-medium text-white">{row.entitas}</td>
                  <td className="py-4 px-6 text-slate-300 max-w-md truncate">{row.keterangan}</td>
                  <td className="py-4 px-4">
                    <StatusBadge status={row.status} tone={row.status_tone} />
                  </td>
                  <td className="py-4 px-6 text-right">
                    <button
                      onClick={() => {
                        if (row.id.startsWith('DS')) setActiveTab('disputes');
                        else if (row.id.startsWith('REP')) setActiveTab('reports');
                        else if (row.id.startsWith('USR')) setActiveTab('users');
                        else setActiveTab('escrow');
                      }}
                      className="px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 transition"
                    >
                      Buka Detail
                    </button>
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
