import React, { useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { EvidenceModal } from '../components/EvidenceModal';
import {
  Scale,
  ShieldCheck,
  AlertTriangle,
  FileText,
  Image as ImageIcon,
  CheckCircle2,
  Clock,
  User,
  Gavel,
  ArrowRight,
  Split,
  Undo2,
  Send,
  HelpCircle,
} from 'lucide-react';

export function DisputePage({ disputes = [], onResolveDispute }) {
  const [selectedVerdict, setSelectedVerdict] = useState('SPLIT_50_50');
  const [deliberationNotes, setDeliberationNotes] = useState(
    'Berdasarkan investigasi bukti, pemesan meminta penambahan 3 logo sponsor baru tanpa penambahan tenggat waktu, sedangkan penyedia telah menyelesaikan 80% progres desain. Putusan adil berimbang: dana dibagi rata 50:50.'
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [verdictSuccess, setVerdictSuccess] = useState(null);
  const [evidencePreview, setEvidencePreview] = useState(null);
  const [disputeTypeTab, setDisputeTypeTab] = useState('tunai'); // 'tunai' atau 'barter'

  const dispute = disputes[0] || {
    case_id: 'DS-2024-004',
    judul_layanan: 'Jasa Desain Spanduk Dies Natalis UPI Cibiru',
    nilai_escrow: 50000,
    status_escrow: 'Terkunci di Rekening Penampungan Simulasi',
    status_perkara: 'Sidang Mediasi Terbuka (SLA Overdue 26 Jam)',
    rekomendasi_sistem: 'Split 50:50 (Rp 25.000 Klien / Rp 25.000 Penyedia)',
    klien: {
      nama: 'Dimas Arya',
      email: 'dimas@gmail.com',
      nim: '2201948',
      prodi: 'Pendidikan Multimedia',
      argumen:
        'Keterlambatan pengerjaan 2 hari melebihi batas waktu deadline yang disepakati bersama. Acara sudah mendekati hari-H dan tidak ada draft final yang bisa langsung dicetak.',
      bukti_nama: 'bukti-chat-whatsapp-deadline.png',
      tuntutan: 'Refund Penuh 100% (Rp 50.000)',
    },
    penyedia: {
      nama: 'Salma Nur Oktavia',
      email: 'salma@gmail.com',
      nim: '2203102',
      prodi: 'Rekayasa Perangkat Lunak',
      argumen:
        'Progres pengerjaan banner spanduk sudah 80% (telah diserahkan draft vector). Keterlambatan terjadi akibat pemesan meminta revisi ukuran dan penambahan 3 logo sponsor di luar kesepakatan awal tanpa perpanjangan waktu.',
      bukti_nama: 'draft-spanduk-80percent.pdf',
      progres_kerja: '80%',
      tuntutan: 'Pencairan Proporsional (Kompensasi Kerja)',
    },
  };

  const handleSubmitVerdict = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const res = await onResolveDispute(
        dispute.case_id,
        selectedVerdict,
        deliberationNotes
      );
      setVerdictSuccess(res);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
            <Scale className="w-6 h-6 text-emerald-400" />
            <span>Sidang Mediasi & Putusan Arbitrase Sengketa</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Pemeriksaan bukti dua arah (Klien vs Penyedia), analisis progres kerja, dan eksekusi pelepasan/pengembalian saldo escrow.
          </p>
        </div>

        {/* Tab Jenis Sengketa (Cash Escrow vs Smart Barter) */}
        <div className="flex items-center gap-1.5 p-1 bg-slate-900 border border-slate-800 rounded-xl">
          <button
            onClick={() => setDisputeTypeTab('tunai')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
              disputeTypeTab === 'tunai'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Escrow Tunai (#DS-2024-004)
          </button>
          <button
            onClick={() => setDisputeTypeTab('barter')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
              disputeTypeTab === 'barter'
                ? 'bg-purple-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Smart Barter Non-Tunai
          </button>
        </div>
      </div>

      {disputeTypeTab === 'barter' ? (
        <div className="p-8 rounded-2xl bg-slate-900/80 border border-purple-800/40 text-center space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-purple-950 border border-purple-600/50 flex items-center justify-center text-purple-400 mx-auto">
            <Scale className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-white">Sidang Arbitrase Smart Barter Non-Tunai</h3>
          <p className="text-xs text-slate-300 max-w-lg mx-auto leading-relaxed">
            Pada sengketa Smart Barter (#BTR-2024-012), resolusi tidak melibatkan dana tunai rupiah melainkan:
            penalti reputasi skor barter, pembatalan kewajiban timbal balik, atau mandat perpanjangan masa kompensasi jasa.
          </p>
          <div className="p-4 rounded-xl bg-purple-950/40 border border-purple-800/40 max-w-md mx-auto text-xs text-purple-300 font-medium">
            Status: Seluruh kontrak barter aktif saat ini berjalan lancar tanpa eskalasi sengketa resmi.
          </div>
        </div>
      ) : (
        <>
          {/* Case Header Banner */}
          <div className="p-5 rounded-2xl bg-[#111827] border border-slate-800 shadow-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-500/20 text-rose-400 border border-rose-500/30">
                  Perkara #{dispute.case_id}
                </span>
                <span className="text-xs text-slate-400 font-medium">
                  {dispute.status_perkara}
                </span>
              </div>
              <h2 className="text-lg font-bold text-white">{dispute.judul_layanan}</h2>
              <p className="text-xs text-slate-400">
                Pihak Terperkara: <strong className="text-slate-200">{dispute.klien.nama}</strong> (Klien) vs{' '}
                <strong className="text-slate-200">{dispute.penyedia.nama}</strong> (Penyedia)
              </p>
            </div>

            <div className="text-right bg-slate-900/90 p-4 rounded-xl border border-slate-800 shrink-0">
              <span className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">
                Dana Terkunci di Penampungan
              </span>
              <p className="text-2xl font-mono font-bold text-emerald-400 mt-0.5">
                Rp {dispute.nilai_escrow.toLocaleString('id-ID')}
              </p>
              <span className="text-[10px] text-amber-400 font-medium flex items-center justify-end gap-1 mt-1">
                <ShieldCheck className="w-3 h-3" />
                Simulasi Escrow Terkunci
              </span>
            </div>
          </div>

          {/* Success Banner if Verdict Executed */}
          {verdictSuccess && (
            <div className="p-5 rounded-2xl bg-emerald-950/60 border border-emerald-500/50 shadow-xl space-y-2">
              <div className="flex items-center gap-2 text-emerald-300 font-bold text-sm">
                <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                <span>Putusan Arbitrase Berhasil Ditetapkan & Dieksekusi!</span>
              </div>
              <p className="text-xs text-slate-200">
                <strong>Hasil:</strong> {verdictSuccess.putusan_resmi}
              </p>
              <div className="p-3 bg-emerald-900/40 rounded-xl text-xs font-mono text-emerald-200 flex gap-6">
                <span>Pencairan Klien: Rp {verdictSuccess.pembagian_saldo?.klien?.toLocaleString('id-ID')}</span>
                <span>Pencairan Penyedia: Rp {verdictSuccess.pembagian_saldo?.penyedia?.toLocaleString('id-ID')}</span>
              </div>
            </div>
          )}

          {/* Dual Columns: Client Claim vs Provider Defense */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Kolom Kiri: Klaim Klien */}
            <div className="bg-[#111827] border border-slate-800 rounded-2xl p-6 space-y-4 shadow-lg relative">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-blue-950 border border-blue-600/50 flex items-center justify-center font-bold text-xs text-blue-400">
                    KL
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-white">{dispute.klien.nama}</h3>
                    <p className="text-[11px] text-slate-400">
                      NIM {dispute.klien.nim} • {dispute.klien.prodi}
                    </p>
                  </div>
                </div>
                <span className="px-2.5 py-1 rounded-full text-[11px] font-semibold bg-blue-950/60 text-blue-400 border border-blue-800/40">
                  Pihak Pemesan (Klien)
                </span>
              </div>

              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Argumen & Alasan Gugatan
                </label>
                <div className="mt-2 p-3.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-200 leading-relaxed">
                  "{dispute.klien.argumen}"
                </div>
              </div>

              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Bukti Dilampirkan
                </label>
                <div
                  onClick={() =>
                    setEvidencePreview({
                      title: 'Bukti Chat WhatsApp Batas Waktu (Klien)',
                      fileName: dispute.klien.bukti_nama,
                    })
                  }
                  className="mt-2 p-3 rounded-xl bg-slate-900 hover:bg-slate-850 border border-slate-700/80 cursor-pointer transition flex items-center justify-between group"
                >
                  <div className="flex items-center gap-2.5">
                    <ImageIcon className="w-4 h-4 text-emerald-400" />
                    <span className="text-xs font-mono text-slate-200 group-hover:text-emerald-300">
                      {dispute.klien.bukti_nama}
                    </span>
                  </div>
                  <span className="text-[11px] text-slate-400 group-hover:text-white">Buka Bukti</span>
                </div>
              </div>

              <div className="pt-2 border-t border-slate-800/80 flex items-center justify-between">
                <span className="text-xs text-slate-400">Tuntutan Klien:</span>
                <span className="text-xs font-bold text-rose-400 bg-rose-950/50 px-2.5 py-1 rounded-lg border border-rose-800/40">
                  {dispute.klien.tuntutan}
                </span>
              </div>
            </div>

            {/* Kolom Kanan: Pembelaan Penyedia */}
            <div className="bg-[#111827] border border-slate-800 rounded-2xl p-6 space-y-4 shadow-lg relative">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-emerald-950 border border-emerald-600/50 flex items-center justify-center font-bold text-xs text-emerald-400">
                    PY
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-white">{dispute.penyedia.nama}</h3>
                    <p className="text-[11px] text-slate-400">
                      NIM {dispute.penyedia.nim} • {dispute.penyedia.prodi}
                    </p>
                  </div>
                </div>
                <span className="px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-950/60 text-emerald-400 border border-emerald-800/40">
                  Pihak Penyedia Jasa
                </span>
              </div>

              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Argumen & Pembelaan Penyedia
                </label>
                <div className="mt-2 p-3.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-200 leading-relaxed">
                  "{dispute.penyedia.argumen}"
                </div>
              </div>

              {/* Progress Bar Pengerjaan */}
              <div>
                <div className="flex items-center justify-between text-xs mb-1.5">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                    Progres Terverifikasi Penyedia
                  </span>
                  <span className="font-bold text-emerald-400">{dispute.penyedia.progres_kerja}</span>
                </div>
                <div className="w-full bg-slate-800 h-2.5 rounded-full overflow-hidden border border-slate-700">
                  <div className="bg-emerald-500 h-full rounded-full w-[80%] transition-all"></div>
                </div>
              </div>

              <div>
                <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Bukti Dilampirkan
                </label>
                <div
                  onClick={() =>
                    setEvidencePreview({
                      title: 'Draft Berkas Desain Spanduk 80% (Penyedia)',
                      fileName: dispute.penyedia.bukti_nama,
                    })
                  }
                  className="mt-2 p-3 rounded-xl bg-slate-900 hover:bg-slate-850 border border-slate-700/80 cursor-pointer transition flex items-center justify-between group"
                >
                  <div className="flex items-center gap-2.5">
                    <FileText className="w-4 h-4 text-rose-400" />
                    <span className="text-xs font-mono text-slate-200 group-hover:text-rose-300">
                      {dispute.penyedia.bukti_nama}
                    </span>
                  </div>
                  <span className="text-[11px] text-slate-400 group-hover:text-white">Buka Bukti</span>
                </div>
              </div>

              <div className="pt-2 border-t border-slate-800/80 flex items-center justify-between">
                <span className="text-xs text-slate-400">Tuntutan Penyedia:</span>
                <span className="text-xs font-bold text-emerald-400 bg-emerald-950/50 px-2.5 py-1 rounded-lg border border-emerald-800/40">
                  {dispute.penyedia.tuntutan}
                </span>
              </div>
            </div>
          </div>

          {/* Panel Putusan Arbitrase Hakim/Admin (Figma Screen 5 Core) */}
          <form
            onSubmit={handleSubmitVerdict}
            className="bg-[#111827] border border-slate-800 rounded-2xl p-6 space-y-6 shadow-xl"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2.5">
                <Gavel className="w-5 h-5 text-emerald-400" />
                <h3 className="text-base font-bold text-white">Panel Putusan Arbitrase Administrator</h3>
              </div>
              <span className="text-xs text-slate-400">
                Rekomendasi Sistem:{' '}
                <strong className="text-emerald-400">{dispute.rekomendasi_sistem}</strong>
              </span>
            </div>

            {/* 3 Opsi Putusan */}
            <div className="space-y-3">
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-400">
                Pilih Opsi Keputusan Akhir
              </label>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {[
                  {
                    id: 'REFUND_100',
                    label: 'Opsi A: Pengembalian Penuh (100%)',
                    desc: 'Klien menerima Rp 50.000. Penyedia menerima Rp 0. Pesanan dibatalkan.',
                    color: 'border-rose-500 bg-rose-950/20 text-rose-300',
                    badge: 'Refund 100%',
                  },
                  {
                    id: 'RELEASE_100',
                    label: 'Opsi B: Pelepasan Penuh (100%)',
                    desc: 'Penyedia menerima Rp 50.000. Klien menerima Rp 0. Pesanan ditandai selesai.',
                    color: 'border-blue-500 bg-blue-950/20 text-blue-300',
                    badge: 'Cair 100%',
                  },
                  {
                    id: 'SPLIT_50_50',
                    label: 'Opsi C: Split 50:50 (Rekomendasi Sistem)',
                    desc: 'Klien menerima Rp 25.000, Penyedia menerima Rp 25.000 sebagai kompensasi 80% kerja.',
                    color: 'border-emerald-500 bg-emerald-950/30 text-emerald-300',
                    badge: 'Rekomendasi Berimbang',
                  },
                ].map((opt) => {
                  const isSelected = selectedVerdict === opt.id;
                  return (
                    <div
                      key={opt.id}
                      onClick={() => setSelectedVerdict(opt.id)}
                      className={`p-4 rounded-xl border-2 cursor-pointer transition flex flex-col justify-between ${
                        isSelected
                          ? opt.color + ' shadow-lg shadow-emerald-950/30'
                          : 'border-slate-800 bg-slate-900/60 hover:border-slate-700'
                      }`}
                    >
                      <div className="space-y-2">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                            {opt.badge}
                          </span>
                          <input
                            type="radio"
                            name="verdict"
                            checked={isSelected}
                            onChange={() => setSelectedVerdict(opt.id)}
                            className="text-emerald-500 focus:ring-emerald-500"
                          />
                        </div>
                        <h4 className="text-xs font-bold text-white">{opt.label}</h4>
                        <p className="text-[11px] text-slate-400 leading-relaxed">{opt.desc}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Catatan Pertimbangan */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">
                Pertimbangan Hukum & Berita Acara Putusan Hakim/Admin
              </label>
              <textarea
                value={deliberationNotes}
                onChange={(e) => setDeliberationNotes(e.target.value)}
                placeholder="Tuliskan dasar pertimbangan objektif berdasarkan bukti obrolan dan berkas..."
                className="w-full px-4 py-3 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition resize-none h-24"
              ></textarea>
            </div>

            {/* Submit Action */}
            <div className="flex items-center justify-between pt-4 border-t border-slate-800">
              <span className="text-xs text-slate-400 flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-emerald-400" />
                Keputusan bersifat final dan dieksekusi seketika pada buku besar saldo simulasi.
              </span>
              <button
                type="submit"
                disabled={isSubmitting}
                className="flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-xs text-white bg-emerald-600 hover:bg-emerald-500 transition shadow-lg shadow-emerald-950/50 disabled:opacity-50"
              >
                <Gavel className="w-4 h-4" />
                <span>Kirim Putusan Resmi & Eksekusi Escrow</span>
              </button>
            </div>
          </form>
        </>
      )}

      {/* Evidence Viewer Modal */}
      <EvidenceModal
        isOpen={!!evidencePreview}
        onClose={() => setEvidencePreview(null)}
        title={evidencePreview?.title}
        fileName={evidencePreview?.fileName}
      />
    </div>
  );
}
