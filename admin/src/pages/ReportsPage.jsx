import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { EvidenceModal } from '../components/EvidenceModal';
import {
  AlertTriangle,
  Search,
  CheckCircle2,
  Clock,
  User,
  ShieldAlert,
  Image as ImageIcon,
  CheckSquare,
  Square,
  Send,
  Flag,
} from 'lucide-react';

export function ReportsPage({ reports = [], onResolveReport }) {
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [selectedReportId, setSelectedReportId] = useState('REP-059');
  const [sanctionChoice, setSanctionChoice] = useState('Blokir Kirim Pesan 3 Hari');
  const [officerNotes, setOfficerNotes] = useState(
    'Terbukti mengajak transaksi bypass rekening bersama via WhatsApp. Diberikan sanksi pembatasan kirim pesan 3 hari dan peringatan tingkat 1.'
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [evidencePreview, setEvidencePreview] = useState(null);
  const [resolutionSuccess, setResolutionSuccess] = useState(false);

  const filters = [
    { id: 'Semua', label: 'Semua Tiket' },
    { id: 'Menunggu', label: 'Menunggu Tindakan' },
    { id: 'Investigasi', label: 'Dalam Investigasi' },
    { id: 'Selesai', label: 'Selesai' },
  ];

  const filteredReports = reports.filter((r) => {
    if (activeFilter === 'Menunggu' && !r.status_tiket?.includes('Menunggu')) return false;
    if (activeFilter === 'Investigasi' && !r.status_tiket?.includes('Investigasi')) return false;
    if (activeFilter === 'Selesai' && !r.status_tiket?.includes('Selesai')) return false;
    return true;
  });

  const selectedReport =
    reports.find((r) => r.report_id === selectedReportId) || reports[0];

  const handleAction = async (e) => {
    e.preventDefault();
    if (!selectedReport) return;
    setIsSubmitting(true);
    try {
      await onResolveReport(selectedReport.report_id, sanctionChoice, officerNotes);
      setResolutionSuccess(true);
      setTimeout(() => setResolutionSuccess(false), 4000);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
          <AlertTriangle className="w-6 h-6 text-amber-400" />
          <span>Manajemen Laporan & Pengaduan Pelanggaran</span>
        </h1>
        <p className="text-xs text-slate-400 mt-1">
          Investigasi aduan pelanggaran bypass escrow, indikasi akun joki, dan pelanggaran norma komunikasi antar-mahasiswa.
        </p>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-1.5 p-1 rounded-xl bg-slate-900 border border-slate-800 w-fit">
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

      {/* Two Column Layout: List Left, Details Right */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Tickets List */}
        <div className="lg:col-span-5 bg-[#111827] border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
          <div className="p-4 border-b border-slate-800 bg-[#0F172A] flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Daftar Tiket Pengaduan
            </span>
            <span className="text-xs font-medium text-slate-400">
              {filteredReports.length} tiket
            </span>
          </div>

          <div className="divide-y divide-slate-800/60 max-h-[650px] overflow-y-auto">
            {filteredReports.map((r) => {
              const isSelected = r.report_id === selectedReport?.report_id;
              return (
                <div
                  key={r.report_id}
                  onClick={() => setSelectedReportId(r.report_id)}
                  className={`p-4 cursor-pointer transition ${
                    isSelected
                      ? 'bg-slate-800/80 border-l-4 border-l-emerald-500'
                      : 'hover:bg-slate-850/40'
                  }`}
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-mono text-xs font-bold text-emerald-400">
                      #{r.report_id}
                    </span>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                        r.prioritas === 'Tinggi'
                          ? 'bg-rose-950/60 text-rose-400 border-rose-800/40'
                          : 'bg-amber-950/60 text-amber-400 border-amber-800/40'
                      }`}
                    >
                      Prioritas {r.prioritas || 'Sedang'}
                    </span>
                  </div>

                  <h4 className="text-xs font-bold text-white line-clamp-1">{r.kategori}</h4>
                  <p className="text-[11px] text-slate-400 mt-1 line-clamp-2 leading-relaxed">
                    {r.deskripsi}
                  </p>

                  <div className="mt-3 pt-2 border-t border-slate-800/60 flex items-center justify-between text-[11px] text-slate-400">
                    <span>Pelapor: {r.pelapor_nama}</span>
                    <StatusBadge status={r.status_tiket} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Ticket Detail & Decision Panel */}
        <div className="lg:col-span-7 bg-[#111827] border border-slate-800 rounded-2xl p-6 shadow-xl space-y-6">
          {selectedReport ? (
            <>
              {/* Ticket Header */}
              <div className="flex items-start justify-between pb-4 border-b border-slate-800">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-sm font-bold text-emerald-400">
                      #{selectedReport.report_id}
                    </span>
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-950/60 text-rose-400 border border-rose-800/40">
                      Prioritas {selectedReport.prioritas || 'Tinggi'}
                    </span>
                  </div>
                  <h2 className="text-base font-bold text-white mt-1.5">{selectedReport.kategori}</h2>
                </div>
                <StatusBadge status={selectedReport.status_tiket} />
              </div>

              {/* Success alert */}
              {resolutionSuccess && (
                <div className="p-3.5 rounded-xl bg-emerald-950/60 border border-emerald-500/50 flex items-center gap-2 text-xs text-emerald-300 font-bold">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  <span>Tindakan sanksi berhasil dicatat dan status tiket diubah menjadi Selesai!</span>
                </div>
              )}

              {/* Pelapor vs Terlapor Details */}
              <div className="grid grid-cols-2 gap-4">
                <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800">
                  <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    Pihak Pelapor
                  </span>
                  <p className="text-xs font-bold text-white mt-0.5">{selectedReport.pelapor_nama}</p>
                  <p className="text-[11px] text-slate-400 font-mono">NIM: {selectedReport.pelapor_nim || '2201948'}</p>
                </div>
                <div className="p-3.5 rounded-xl bg-rose-950/20 border border-rose-900/40">
                  <span className="text-[10px] font-bold uppercase tracking-wider text-rose-400">
                    Pihak Terlapor
                  </span>
                  <p className="text-xs font-bold text-white mt-0.5">{selectedReport.terlapor_nama}</p>
                  <p className="text-[11px] text-rose-300 font-mono">NIM: {selectedReport.terlapor_nim || '2208173'}</p>
                </div>
              </div>

              {/* Uraian Kronologi Aduan */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                  Uraian Kronologi Pengaduan
                </label>
                <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-200 leading-relaxed">
                  "{selectedReport.deskripsi}"
                </div>
              </div>

              {/* Bukti Terlampir */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                  Bukti Terlampir
                </label>
                <div
                  onClick={() =>
                    setEvidencePreview({
                      title: `Bukti Aduan #${selectedReport.report_id}`,
                      fileName: selectedReport.bukti_file || 'bukti-chat-bypass.png',
                    })
                  }
                  className="p-3 rounded-xl bg-slate-900 hover:bg-slate-850 border border-slate-700 cursor-pointer transition flex items-center justify-between group"
                >
                  <div className="flex items-center gap-2.5">
                    <ImageIcon className="w-4 h-4 text-emerald-400" />
                    <span className="text-xs font-mono text-slate-200 group-hover:text-emerald-300">
                      {selectedReport.bukti_file || 'bukti-chat-bypass.png'}
                    </span>
                  </div>
                  <span className="text-[11px] text-slate-400 group-hover:text-white">
                    Buka Pratinjau Bukti
                  </span>
                </div>
              </div>

              {/* Form Keputusan Petugas (Figma Screen 6 Core) */}
              <form onSubmit={handleAction} className="pt-4 border-t border-slate-800 space-y-4">
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300">
                  Tindakan Penegakan Tata Tertib
                </label>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {[
                    { id: 'Peringatan Tingkat 1', label: 'Peringatan Tingkat 1' },
                    { id: 'Blokir Kirim Pesan 3 Hari', label: 'Blokir Pesan 3 Hari' },
                    { id: 'Ban Akun Permanen', label: 'Ban Permanen' },
                  ].map((s) => {
                    const isChecked = sanctionChoice === s.id;
                    return (
                      <div
                        key={s.id}
                        onClick={() => setSanctionChoice(s.id)}
                        className={`p-3 rounded-xl border cursor-pointer transition flex items-center gap-2 text-xs font-semibold ${
                          isChecked
                            ? 'bg-rose-950/40 border-rose-500 text-rose-300'
                            : 'bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700'
                        }`}
                      >
                        {isChecked ? (
                          <CheckSquare className="w-4 h-4 text-rose-400 shrink-0" />
                        ) : (
                          <Square className="w-4 h-4 text-slate-600 shrink-0" />
                        )}
                        <span>{s.label}</span>
                      </div>
                    );
                  })}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                    Catatan Petugas Investigasi
                  </label>
                  <textarea
                    value={officerNotes}
                    onChange={(e) => setOfficerNotes(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition resize-none h-18"
                  ></textarea>
                </div>

                <div className="flex justify-end pt-2">
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="flex items-center gap-2 px-5 py-2.5 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 transition shadow-lg shadow-emerald-950/40 disabled:opacity-50"
                  >
                    <Send className="w-4 h-4" />
                    <span>Simpan & Tindak Lanjuti Laporan</span>
                  </button>
                </div>
              </form>
            </>
          ) : (
            <div className="py-20 text-center text-slate-500 text-xs">
              Pilih tiket di kolom kiri untuk melihat rincian aduan.
            </div>
          )}
        </div>
      </div>

      {/* Evidence Viewer */}
      <EvidenceModal
        isOpen={!!evidencePreview}
        onClose={() => setEvidencePreview(null)}
        title={evidencePreview?.title}
        fileName={evidencePreview?.fileName}
      />
    </div>
  );
}
