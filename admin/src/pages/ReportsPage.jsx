import React, { useState, useEffect } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { EvidenceModal } from '../components/EvidenceModal';
import { AlertTriangle, CheckCircle2, Send, Link2, Inbox } from 'lucide-react';

export function ReportsPage({ reports = [], onResolveReport }) {
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [selectedReportId, setSelectedReportId] = useState(null);
  const [actionChoice, setActionChoice] = useState('Peringatan Resmi & Selesaikan');
  const [officerNotes, setOfficerNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [evidenceOpen, setEvidenceOpen] = useState(false);
  const [resolutionSuccess, setResolutionSuccess] = useState('');

  useEffect(() => {
    if (reports.length > 0 && !reports.some((r) => r.report_id === selectedReportId)) {
      setSelectedReportId(reports[0].report_id);
    }
  }, [reports, selectedReportId]);

  const filters = [
    { id: 'Semua', label: `Semua (${reports.length})` },
    { id: 'Baru', label: `Baru (${reports.filter((r) => r.status_penanganan === 'Baru').length})` },
    {
      id: 'Ditinjau',
      label: `Ditinjau (${reports.filter((r) => r.status_penanganan === 'Ditinjau').length})`,
    },
    {
      id: 'Selesai',
      label: `Selesai (${reports.filter((r) => r.status_penanganan === 'Selesai').length})`,
    },
  ];

  const filteredReports = reports.filter((r) => {
    if (activeFilter === 'Semua') return true;
    return r.status_penanganan === activeFilter;
  });

  const selectedReport =
    reports.find((r) => r.report_id === selectedReportId) || filteredReports[0] || null;

  const handleAction = async (e) => {
    e.preventDefault();
    if (!selectedReport) return;
    setIsSubmitting(true);
    try {
      await onResolveReport(
        selectedReport.report_id,
        actionChoice,
        officerNotes.trim() || 'Ditindaklanjuti melalui Portal Admin SakuSkill'
      );
      setResolutionSuccess(
        `Tiket #${selectedReport.short_id} berhasil diperbarui (${actionChoice}).`
      );
      setOfficerNotes('');
      setTimeout(() => setResolutionSuccess(''), 4000);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight flex items-center gap-2.5">
          <AlertTriangle className="w-6 h-6 text-[#B45309]" />
          <span>Manajemen Laporan & Komplain Pengguna</span>
        </h1>
        <p className="text-xs text-[#64748B] mt-1">
          Tiket komplain & laporan pelanggaran yang dikirim langsung dari fitur Pusat Bantuan / Komplain aplikasi mobile.
        </p>
      </div>

      <div className="flex items-center gap-1.5 p-1.5 rounded-2xl clay-tile w-fit overflow-x-auto">
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

      {reports.length === 0 ? (
        <div className="clay-card p-12 text-center space-y-3">
          <div className="w-14 h-14 rounded-2xl bg-[#ECFDF5] border border-[#A7F3D0] text-[#059669] flex items-center justify-center mx-auto">
            <Inbox className="w-7 h-7" />
          </div>
          <h3 className="text-base font-extrabold text-[#0F172A]">
            Belum Ada Laporan / Komplain Masuk
          </h3>
          <p className="text-xs text-[#64748B] max-w-md mx-auto">
            Saat pengguna mengirim komplain pesanan, barter, atau laporan pelanggaran dari HP, tiketnya otomatis muncul secara real-time di halaman ini.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Ticket List */}
          <div className="lg:col-span-5 clay-card overflow-hidden">
            <div className="px-5 py-4 border-b border-[#E6EFEA] bg-white/70 flex items-center justify-between">
              <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#64748B]">
                Daftar Tiket Masuk
              </span>
              <span className="text-xs font-bold text-[#0F172A]">
                {filteredReports.length} tiket
              </span>
            </div>

            <div className="divide-y divide-[#EEF3F0] max-h-[620px] overflow-y-auto">
              {filteredReports.map((r) => {
                const isSelected = r.report_id === selectedReport?.report_id;
                return (
                  <button
                    type="button"
                    key={r.report_id}
                    onClick={() => setSelectedReportId(r.report_id)}
                    className={`w-full text-left p-4 transition block ${
                      isSelected
                        ? 'bg-[#ECFDF5]/70 border-l-4 border-l-[#059669]'
                        : 'hover:bg-[#F7FAF8]'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1.5 gap-2">
                      <span className="font-mono text-xs font-extrabold text-[#059669]">
                        #{r.short_id} · {r.target_tipe}
                      </span>
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                          r.prioritas === 'Tinggi'
                            ? 'bg-[#FEF2F2] text-[#DC2626] border-[#FECACA]'
                            : 'bg-[#FFFBEB] text-[#B45309] border-[#FDE68A]'
                        }`}
                      >
                        {r.prioritas}
                      </span>
                    </div>

                    <h4 className="text-xs font-extrabold text-[#0F172A] line-clamp-1">
                      {r.kategori}
                    </h4>
                    <p className="text-[11px] text-[#64748B] mt-1 line-clamp-2 leading-relaxed">
                      {r.deskripsi}
                    </p>

                    <div className="mt-3 pt-2 border-t border-[#EEF3F0] flex items-center justify-between text-[11px] text-[#64748B]">
                      <span className="font-medium truncate">Pelapor: {r.pelapor_nama}</span>
                      <StatusBadge status={r.status_penanganan} />
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Detail & Action Panel */}
          <div className="lg:col-span-7 clay-card p-6 space-y-5">
            {selectedReport ? (
              <>
                <div className="flex items-start justify-between pb-4 border-b border-[#E6EFEA] gap-3">
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-mono text-sm font-extrabold text-[#059669]">
                        #{selectedReport.short_id}
                      </span>
                      <StatusBadge status={selectedReport.target_tipe} tone="purple" />
                    </div>
                    <h2 className="text-base font-extrabold text-[#0F172A] mt-1.5">
                      {selectedReport.kategori}
                    </h2>
                    <p className="text-[11px] text-[#64748B] mt-0.5">
                      Objek terkait: <strong className="text-[#0F172A]">{selectedReport.target_ringkas}</strong>
                    </p>
                  </div>
                  <StatusBadge status={selectedReport.status_penanganan} />
                </div>

                {resolutionSuccess && (
                  <div className="p-3.5 rounded-2xl bg-[#ECFDF5] border border-[#A7F3D0] flex items-center gap-2 text-xs text-[#065F46] font-bold">
                    <CheckCircle2 className="w-4 h-4 text-[#059669] shrink-0" />
                    <span>{resolutionSuccess}</span>
                  </div>
                )}

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="clay-tile p-3.5">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-[#64748B]">
                      Pihak Pelapor
                    </span>
                    <p className="text-xs font-extrabold text-[#0F172A] mt-0.5">
                      {selectedReport.pelapor_nama}
                    </p>
                    <p className="text-[11px] text-[#64748B] font-mono">
                      {selectedReport.pelapor_email}
                    </p>
                  </div>
                  <div className="clay-tile p-3.5">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-[#64748B]">
                      Target / Referensi ID
                    </span>
                    <p className="text-xs font-extrabold text-[#0F172A] mt-0.5">
                      {selectedReport.target_tipe}: {selectedReport.target_ringkas}
                    </p>
                    <p className="text-[10.5px] text-[#64748B] font-mono truncate">
                      {selectedReport.target_id}
                    </p>
                  </div>
                </div>

                <div>
                  <label className="block text-[11px] font-bold uppercase tracking-wider text-[#64748B] mb-1.5">
                    Kronologi & Isi Komplain Pengguna
                  </label>
                  <div className="clay-tile p-4 text-xs text-[#0F172A] leading-relaxed whitespace-pre-wrap">
                    {selectedReport.deskripsi}
                  </div>
                </div>

                <div className="flex items-center justify-between gap-3">
                  <button
                    type="button"
                    onClick={() => setEvidenceOpen(true)}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#F0F4F2] hover:bg-[#ECFDF5] text-xs font-bold text-[#059669] border border-[#DCE5E0] transition"
                  >
                    <Link2 className="w-3.5 h-3.5" />
                    <span>
                      Lihat Tautan Bukti ({selectedReport.bukti_urls?.length || 0})
                    </span>
                  </button>

                  {selectedReport.keputusan && (
                    <span className="text-[11px] text-[#047857] font-semibold">
                      Putusan: {selectedReport.keputusan}
                    </span>
                  )}
                </div>

                <form onSubmit={handleAction} className="pt-4 border-t border-[#E6EFEA] space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
                      Tindakan Penanganan Administrator
                    </label>
                    <select
                      value={actionChoice}
                      onChange={(e) => setActionChoice(e.target.value)}
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] focus:outline-none focus:border-[#059669]"
                    >
                      <option value="Tandai Ditinjau">Tandai Sedang Ditinjau (Investigasi)</option>
                      <option value="Peringatan Resmi & Selesaikan">
                        Beri Peringatan Resmi & Selesaikan Tiket
                      </option>
                      <option value="Mediasi Selesai & Tutup Tiket">
                        Mediasi Tercapai & Tandai Selesai
                      </option>
                      <option value="Laporan Tidak Terbukti / Ditutup">
                        Tidak Terbukti Melanggar & Tutup Tiket
                      </option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
                      Catatan Berita Acara Petugas
                    </label>
                    <textarea
                      value={officerNotes}
                      onChange={(e) => setOfficerNotes(e.target.value)}
                      placeholder="Tuliskan catatan pemeriksaan atau hasil klarifikasi..."
                      className="w-full px-3.5 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] transition resize-none h-20"
                    />
                  </div>

                  <div className="flex justify-end">
                    <button
                      type="submit"
                      disabled={isSubmitting}
                      className="clay-btn-primary px-5 py-2.5 text-xs inline-flex items-center gap-2"
                    >
                      <Send className="w-3.5 h-3.5" />
                      <span>{isSubmitting ? 'Menyimpan...' : 'Simpan Tindak Lanjut'}</span>
                    </button>
                  </div>
                </form>
              </>
            ) : (
              <div className="py-12 text-center text-xs text-[#64748B]">
                Pilih salah satu tiket pengaduan di sebelah kiri untuk meninjau detailnya.
              </div>
            )}
          </div>
        </div>
      )}

      <EvidenceModal
        isOpen={evidenceOpen}
        onClose={() => setEvidenceOpen(false)}
        title={`Tautan Bukti Tiket #${selectedReport?.short_id || ''}`}
        urls={selectedReport?.bukti_urls || []}
        description={selectedReport?.deskripsi || ''}
      />
    </div>
  );
}
