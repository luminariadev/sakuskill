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
  CheckCircle2,
  Clock,
} from 'lucide-react';

export function DashboardPage({ data, setActiveTab }) {
  const kpi = data?.kpi || {
    pengguna_terverifikasi: {
      label: 'Total Mahasiswa Terdaftar',
      value: 0,
      subtext: 'Memuat data real-time...',
      trend: 'neutral',
    },
    transaksi_aktif_escrow: {
      label: 'Dana Ditahan Escrow',
      value: 'Rp 0',
      subtext: '0 order · 0 barter aktif',
      trend: 'neutral',
    },
    laporan_dan_sengketa: {
      label: 'Laporan & Sengketa',
      value: '0 Perkara',
      subtext: '0 sengketa · 0 aduan terbuka',
      trend: 'neutral',
    },
    layanan_terdaftar: {
      label: 'Layanan Aktif Katalog',
      value: 0,
      subtext: '0 total listing tercatat',
      trend: 'neutral',
    },
  };

  const summary = data?.summary;
  const slaAlert = data?.sla_alert;
  const activities = data?.aktivitas_terbaru || [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight">
            Dasbor Operasional Kampus
          </h1>
          <p className="text-xs text-[#64748B] mt-1">
            Ringkasan real-time transaksi mobile, Smart Barter Rp 0, verifikasi akun, dan pelaporan di UIN Sunan Gunung Djati Bandung.
          </p>
        </div>
        {summary && (
          <div className="flex flex-wrap items-center gap-2 text-[11px] font-bold">
            <span className="clay-tile px-3 py-1.5 text-[#047857]">
              Escrow Dilepas: Rp {Number(summary.escrow_dilepas || 0).toLocaleString('id-ID')}
            </span>
            <span className="clay-tile px-3 py-1.5 text-[#7E22CE]">
              Total Barter: {summary.total_barter || 0} Kontrak
            </span>
            <span className="clay-tile px-3 py-1.5 text-[#2563EB]">
              Order Selesai: {summary.order_selesai || 0}
            </span>
          </div>
        )}
      </div>

      {/* Conditional SLA / Dispute Alert Banner */}
      {slaAlert ? (
        <div className="clay-card p-5 border-[#FECACA] bg-gradient-to-r from-[#FEF2F2] via-white to-[#FFFBEB] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-11 h-11 rounded-2xl bg-[#FEE2E2] border border-[#FECACA] flex items-center justify-center text-[#DC2626] shrink-0">
              <AlertCircle className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-[10.5px] font-extrabold uppercase tracking-wider text-[#DC2626] bg-white px-2.5 py-0.5 rounded-full border border-[#FECACA]">
                  {slaAlert.status}
                </span>
                <span className="text-xs font-mono font-bold text-[#64748B]">
                  #{slaAlert.short_id || slaAlert.case_id}
                </span>
              </div>
              <h4 className="text-sm font-extrabold text-[#0F172A] mt-1">{slaAlert.title}</h4>
              <p className="text-xs text-[#475569] mt-0.5 leading-relaxed max-w-3xl">
                {slaAlert.message}
              </p>
            </div>
          </div>
          <button
            onClick={() => setActiveTab(slaAlert.target_tab || 'disputes')}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-[#DC2626] hover:bg-[#B91C1C] text-white text-xs font-bold transition shrink-0 shadow-sm"
          >
            <span>Tinjau Perkara</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      ) : (
        <div className="clay-card p-4 border-[#A7F3D0] bg-gradient-to-r from-[#ECFDF5] to-white flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-2xl bg-[#D1FAE5] text-[#047857] flex items-center justify-center shrink-0">
              <CheckCircle2 className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-extrabold text-[#065F46]">
                Seluruh Transaksi & Aduan Dalam Batas SLA
              </p>
              <p className="text-[11.5px] text-[#047857]">
                Tidak ada sengketa atau laporan terbuka yang melewati batas waktu 24 jam saat ini.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* 4 KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5">
        <KpiCard
          title={kpi.pengguna_terverifikasi.label}
          value={Number(kpi.pengguna_terverifikasi.value || 0).toLocaleString('id-ID')}
          subtext={kpi.pengguna_terverifikasi.subtext}
          trend={kpi.pengguna_terverifikasi.trend}
          icon={Users}
          color="emerald"
        />
        <KpiCard
          title={kpi.transaksi_aktif_escrow.label}
          value={kpi.transaksi_aktif_escrow.value}
          subtext={kpi.transaksi_aktif_escrow.subtext}
          trend={kpi.transaksi_aktif_escrow.trend}
          icon={Wallet}
          color="blue"
        />
        <KpiCard
          title={kpi.laporan_dan_sengketa.label}
          value={kpi.laporan_dan_sengketa.value}
          subtext={kpi.laporan_dan_sengketa.subtext}
          trend={kpi.laporan_dan_sengketa.trend}
          icon={AlertTriangle}
          color="rose"
        />
        <KpiCard
          title={kpi.layanan_terdaftar.label}
          value={Number(kpi.layanan_terdaftar.value || 0).toLocaleString('id-ID')}
          subtext={kpi.layanan_terdaftar.subtext}
          trend={kpi.layanan_terdaftar.trend}
          icon={Briefcase}
          color="purple"
        />
      </div>

      {/* Recent Activity Table */}
      <div className="clay-card overflow-hidden">
        <div className="px-6 py-4 border-b border-[#E6EFEA] flex items-center justify-between gap-4 bg-white/70">
          <div>
            <h3 className="text-sm font-extrabold text-[#0F172A]">
              Log Aktivitas Terbaru dari Aplikasi
            </h3>
            <p className="text-[11.5px] text-[#64748B] mt-0.5">
              Registrasi pengguna, pesanan escrow, Smart Barter, dan laporan terbaru di database
            </p>
          </div>
          <span className="inline-flex items-center gap-1.5 text-[11px] font-bold text-[#047857] bg-[#ECFDF5] px-3 py-1 rounded-full border border-[#A7F3D0]">
            <span className="w-2 h-2 rounded-full bg-[#059669] animate-pulse"></span>
            Live DB Feed
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F7FAF8] text-[#64748B] font-bold border-b border-[#E6EFEA] uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3.5 px-4">ID</th>
                <th className="py-3.5 px-3">Waktu</th>
                <th className="py-3.5 px-3">Kategori</th>
                <th className="py-3.5 px-3">Pihak Terlibat</th>
                <th className="py-3.5 px-4">Keterangan</th>
                <th className="py-3.5 px-3">Status</th>
                <th className="py-3.5 px-4 text-right">Navigasi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#EEF3F0]">
              {activities.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-[#64748B] text-xs">
                    Belum ada aktivitas tercatat di database saat ini.
                  </td>
                </tr>
              ) : (
                activities.map((row) => (
                  <tr key={`${row.id}-${row.timestamp}`} className="hover:bg-[#F7FAF8] transition">
                    <td className="py-3.5 px-4 font-mono font-bold text-[#059669] whitespace-nowrap">
                      {row.id}
                    </td>
                    <td className="py-3.5 px-3 text-[#64748B] whitespace-nowrap">
                      <span className="inline-flex items-center gap-1.5">
                        <Clock className="w-3 h-3 text-[#94A3B8]" />
                        <span>{row.waktu}</span>
                      </span>
                    </td>
                    <td className="py-3.5 px-3 font-bold text-[#0F172A] whitespace-nowrap">
                      {row.tipe}
                    </td>
                    <td className="py-3.5 px-3 font-semibold text-[#0F172A]">{row.entitas}</td>
                    <td className="py-3.5 px-4 text-[#475569] max-w-[230px] truncate">{row.keterangan}</td>
                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <StatusBadge status={row.status} tone={row.status_tone} />
                    </td>
                    <td className="py-3.5 px-4 text-right whitespace-nowrap">
                      <button
                        onClick={() => setActiveTab(row.target_tab || 'escrow')}
                        className="px-3 py-1.5 rounded-xl text-[11px] font-bold text-[#0F172A] bg-[#F0F4F2] hover:bg-[#ECFDF5] hover:text-[#047857] border border-[#DCE5E0] transition"
                      >
                        Buka Modul
                      </button>
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
