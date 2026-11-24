import React, { useState, useEffect } from 'react';
import { EvidenceModal } from '../components/EvidenceModal';
import { UserAvatar } from '../components/UserAvatar';
import { StatusBadge } from '../components/StatusBadge';
import {
  Scale,
  ShieldCheck,
  CheckCircle2,
  Gavel,
  Send,
  Link2,
  Shield,
} from 'lucide-react';

export function DisputePage({ disputes = [], onResolveDispute }) {
  const [selectedCaseId, setSelectedCaseId] = useState(null);
  const [selectedVerdict, setSelectedVerdict] = useState('SPLIT_50_50');
  const [deliberationNotes, setDeliberationNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [verdictSuccess, setVerdictSuccess] = useState(null);
  const [evidenceModalOpen, setEvidenceModalOpen] = useState(false);

  useEffect(() => {
    if (disputes.length > 0 && !disputes.some((d) => d.case_id === selectedCaseId)) {
      setSelectedCaseId(disputes[0].case_id);
      setVerdictSuccess(null);
    }
  }, [disputes, selectedCaseId]);

  const dispute =
    disputes.find((d) => d.case_id === selectedCaseId) || disputes[0] || null;

  const handleSubmitVerdict = async (e) => {
    e.preventDefault();
    if (!dispute) return;
    setIsSubmitting(true);
    try {
      const notes =
        deliberationNotes.trim() ||
        'Putusan mediasi ditetapkan berdasarkan pemeriksaan bukti dua pihak di Portal Admin SakuSkill.';
      const res = await onResolveDispute(dispute.case_id, selectedVerdict, notes);
      setVerdictSuccess(res);
      setDeliberationNotes('');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!dispute) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight flex items-center gap-2.5">
            <Scale className="w-6 h-6 text-[#059669]" />
            <span>Sidang Mediasi & Putusan Arbitrase</span>
          </h1>
          <p className="text-xs text-[#64748B] mt-1">
            Daftar real-time pesanan bermasalah dan komplain transaksi dari pengguna aplikasi mobile.
          </p>
        </div>

        <div className="clay-card p-12 text-center space-y-3">
          <div className="w-14 h-14 rounded-2xl bg-[#ECFDF5] border border-[#A7F3D0] text-[#059669] flex items-center justify-center mx-auto shadow-clay-sm">
            <Shield className="w-7 h-7" />
          </div>
          <h2 className="text-base font-extrabold text-[#0F172A]">
            Tidak Ada Sengketa Aktif Saat Ini
          </h2>
          <p className="text-xs text-[#64748B] max-w-md mx-auto leading-relaxed">
            Seluruh transaksi berbayar maupun Smart Barter Rp 0 dari pengguna mobile saat ini berjalan normal tanpa sengketa terbuka.
          </p>
          {verdictSuccess && (
            <div className="mt-4 max-w-lg mx-auto p-4 rounded-2xl bg-[#ECFDF5] border border-[#A7F3D0] text-xs text-[#065F46] font-semibold">
              Putusan terakhir dieksekusi: {verdictSuccess.putusan_resmi}
            </div>
          )}
        </div>
      </div>
    );
  }

  const nominal = Number(dispute.nilai_escrow || 0);
  const half = Math.floor(nominal / 2);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight flex items-center gap-2.5">
            <Scale className="w-6 h-6 text-[#059669]" />
            <span>Sidang Mediasi & Putusan Arbitrase</span>
          </h1>
          <p className="text-xs text-[#64748B] mt-1">
            Menampilkan {disputes.length} perkara terbuka langsung dari database transaksi aplikasi mobile.
          </p>
        </div>

        {disputes.length > 1 && (
          <div className="flex items-center gap-1.5 p-1.5 rounded-2xl clay-tile overflow-x-auto">
            {disputes.map((d) => (
              <button
                key={d.case_id}
                onClick={() => {
                  setSelectedCaseId(d.case_id);
                  setVerdictSuccess(null);
                }}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition shrink-0 ${
                  dispute.case_id === d.case_id
                    ? 'clay-btn-primary'
                    : 'text-[#64748B] hover:text-[#0F172A]'
                }`}
              >
                #{d.short_id} ({d.tipe_transaksi})
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Case Header Banner */}
      <div className="clay-card p-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="space-y-1.5">
          <div className="flex items-center gap-2 flex-wrap">
            <StatusBadge status={`#${dispute.short_id}`} tone="danger" />
            <StatusBadge
              status={dispute.tipe_transaksi}
              tone={dispute.tipe_transaksi === 'Barter' ? 'purple' : 'info'}
            />
            <span className="text-xs font-semibold text-[#64748B]">
              {dispute.status_perkara}
            </span>
          </div>
          <h2 className="text-lg font-extrabold text-[#0F172A]">{dispute.judul_layanan}</h2>
          <p className="text-xs text-[#475569]">
            Pihak Terkait: <strong className="text-[#0F172A]">{dispute.klien?.nama}</strong> vs{' '}
            <strong className="text-[#0F172A]">{dispute.penyedia?.nama}</strong>
          </p>
        </div>

        <div className="hero-emerald-card text-white px-5 py-4 shrink-0 min-w-[230px]">
          <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-200 block">
            Nilai Escrow / Transaksi
          </span>
          <p className="text-2xl font-extrabold font-mono tabular-nums mt-0.5">
            {dispute.tipe_transaksi === 'Barter'
              ? 'Rp 0 (Barter)'
              : `Rp ${nominal.toLocaleString('id-ID')}`}
          </p>
          <span className="inline-flex items-center gap-1 text-[11px] text-emerald-200 mt-1">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>{dispute.status_escrow}</span>
          </span>
        </div>
      </div>

      {verdictSuccess && (
        <div className="clay-card p-5 border-[#A7F3D0] bg-[#ECFDF5] space-y-2">
          <div className="flex items-center gap-2 text-[#065F46] font-extrabold text-sm">
            <CheckCircle2 className="w-5 h-5 text-[#059669]" />
            <span>Putusan Arbitrase Berhasil Disimpan ke Database!</span>
          </div>
          <p className="text-xs text-[#047857]">
            <strong>Keputusan:</strong> {verdictSuccess.putusan_resmi}
          </p>
        </div>
      )}

      {/* Dual Party Columns */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="clay-card p-6 space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-[#E6EFEA]">
            <div className="flex items-center gap-3 min-w-0">
              <UserAvatar
                name={dispute.klien?.nama}
                photoUrl={dispute.klien?.foto_profil}
                sizeClass="w-10 h-10 text-xs"
              />
              <div className="min-w-0">
                <h3 className="text-sm font-extrabold text-[#0F172A] truncate">
                  {dispute.klien?.nama}
                </h3>
                <p className="text-[11px] text-[#64748B] font-mono truncate">
                  {dispute.klien?.email}
                </p>
              </div>
            </div>
            <StatusBadge
              status={dispute.tipe_transaksi === 'Barter' ? 'Pihak Pengaju' : 'Pemesan / Pelapor'}
              tone="info"
            />
          </div>

          <div className="clay-tile p-4 text-xs text-[#0F172A] leading-relaxed">
            <p className="text-[10.5px] font-bold uppercase tracking-wider text-[#64748B] mb-1">
              Keterangan & Tuntutan
            </p>
            <p className="whitespace-pre-wrap">{dispute.klien?.argumen}</p>
          </div>

          <div className="flex items-center justify-between gap-3 pt-1">
            <span className="text-[11px] font-semibold text-[#64748B]">
              {dispute.klien?.tuntutan}
            </span>
            <button
              type="button"
              onClick={() => setEvidenceModalOpen(true)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#F0F4F2] hover:bg-[#ECFDF5] text-xs font-bold text-[#059669] border border-[#DCE5E0] transition"
            >
              <Link2 className="w-3.5 h-3.5" />
              <span>Tautan Bukti ({dispute.bukti_urls?.length || 0})</span>
            </button>
          </div>
        </div>

        <div className="clay-card p-6 space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-[#E6EFEA]">
            <div className="flex items-center gap-3 min-w-0">
              <UserAvatar
                name={dispute.penyedia?.nama}
                photoUrl={dispute.penyedia?.foto_profil}
                sizeClass="w-10 h-10 text-xs"
              />
              <div className="min-w-0">
                <h3 className="text-sm font-extrabold text-[#0F172A] truncate">
                  {dispute.penyedia?.nama}
                </h3>
                <p className="text-[11px] text-[#64748B] font-mono truncate">
                  {dispute.penyedia?.email}
                </p>
              </div>
            </div>
            <StatusBadge
              status={dispute.tipe_transaksi === 'Barter' ? 'Mitra Penerima' : 'Penyedia Jasa'}
              tone="purple"
            />
          </div>

          <div className="clay-tile p-4 text-xs text-[#0F172A] leading-relaxed">
            <p className="text-[10.5px] font-bold uppercase tracking-wider text-[#64748B] mb-1">
              Ruang Lingkup / Kewajiban Tercatat
            </p>
            <p className="whitespace-pre-wrap">{dispute.penyedia?.argumen}</p>
          </div>

          <p className="text-[11px] font-semibold text-[#64748B]">
            {dispute.penyedia?.tuntutan}
          </p>
        </div>
      </div>

      {/* Verdict Decision Form */}
      <form onSubmit={handleSubmitVerdict} className="clay-card p-6 space-y-5">
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-[#ECFDF5] text-[#059669] flex items-center justify-center">
              <Gavel className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-extrabold text-[#0F172A]">
                Penetapan Putusan Mediasi Administrator
              </h3>
              <p className="text-[11px] text-[#64748B]">
                Rekomendasi sistem: {dispute.rekomendasi_sistem}
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            {
              id: 'REFUND_100',
              title:
                dispute.tipe_transaksi === 'Barter'
                  ? 'Batalkan Kontrak Barter'
                  : `Refund 100% (Rp ${nominal.toLocaleString('id-ID')})`,
              desc:
                dispute.tipe_transaksi === 'Barter'
                  ? 'Kontrak barter dihentikan/dibatalkan secara resmi.'
                  : 'Pesanan dibatalkan dan dana simulasi dikembalikan penuh ke pemesan.',
            },
            {
              id: 'SPLIT_50_50',
              title:
                dispute.tipe_transaksi === 'Barter'
                  ? 'Selesaikan Mediasi Berimbang'
                  : `Split 50:50 (Rp ${half.toLocaleString('id-ID')} / Rp ${(nominal - half).toLocaleString('id-ID')})`,
              desc:
                dispute.tipe_transaksi === 'Barter'
                  ? 'Kedua pihak dinyatakan menyelesaikan mediasi secara damai.'
                  : 'Kompromi berimbang dan menandai perkara selesai.',
            },
            {
              id: 'RELEASE_100',
              title:
                dispute.tipe_transaksi === 'Barter'
                  ? 'Nyatakan Barter Selesai'
                  : `Release 100% ke Penyedia (Rp ${nominal.toLocaleString('id-ID')})`,
              desc:
                dispute.tipe_transaksi === 'Barter'
                  ? 'Kewajiban kedua pihak dinyatakan tuntas.'
                  : 'Pesanan diselesaikan penuh dan dana dilepas ke penyedia.',
            },
          ].map((opt) => {
            const active = selectedVerdict === opt.id;
            return (
              <button
                type="button"
                key={opt.id}
                onClick={() => setSelectedVerdict(opt.id)}
                className={`text-left p-4 rounded-2xl border transition ${
                  active
                    ? 'bg-[#ECFDF5] border-[#059669] shadow-clay-sm'
                    : 'bg-white border-[#E6EFEA] hover:border-[#CBD5E1]'
                }`}
              >
                <p className="text-xs font-extrabold text-[#0F172A]">{opt.title}</p>
                <p className="text-[11px] text-[#64748B] mt-1 leading-relaxed">{opt.desc}</p>
              </button>
            );
          })}
        </div>

        <div>
          <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
            Berita Acara Pertimbangan Putusan
          </label>
          <textarea
            value={deliberationNotes}
            onChange={(e) => setDeliberationNotes(e.target.value)}
            placeholder="Tuliskan dasar pertimbangan keputusan mediasi untuk dicatat di audit log & status pesanan..."
            className="w-full px-4 py-3 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] transition resize-none h-24"
          />
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={isSubmitting}
            className="clay-btn-primary px-6 py-3 text-xs inline-flex items-center gap-2"
          >
            <Send className="w-4 h-4" />
            <span>{isSubmitting ? 'Mengeksekusi Putusan...' : 'Tetapkan Putusan Resmi'}</span>
          </button>
        </div>
      </form>

      <EvidenceModal
        isOpen={evidenceModalOpen}
        onClose={() => setEvidenceModalOpen(false)}
        title={`Bukti Perkara #${dispute.short_id}`}
        urls={dispute.bukti_urls || []}
        description={dispute.klien?.argumen || ''}
      />
    </div>
  );
}
