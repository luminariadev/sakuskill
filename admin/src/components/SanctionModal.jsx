import React, { useState } from 'react';
import { Modal } from './Modal';
import { AlertTriangle, Clock, Ban, CheckCircle2 } from 'lucide-react';

export function SanctionModal({ isOpen, onClose, user, onSanction }) {
  const [sanctionType, setSanctionType] = useState('Peringatan Resmi');
  const [reason, setReason] = useState('Upaya transaksi bypass rekening bersama (Escrow)');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!user) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const detail = notes.trim() ? `${reason}. ${notes.trim()}` : reason;
      await onSanction(user.user_id, sanctionType, detail);
      setNotes('');
      onClose();
    } finally {
      setIsSubmitting(false);
    }
  };

  const options = [
    {
      id: 'Peringatan Resmi',
      title: 'Peringatan Resmi (Tingkat 1)',
      desc: 'Mencatat peringatan pelanggaran resmi pada profil & audit log.',
      icon: AlertTriangle,
      tone: 'text-[#B45309]',
    },
    {
      id: 'Bekukan Akun Sementara (7 Hari)',
      title: 'Bekukan Akun Sementara (7 Hari)',
      desc: 'Menandai akun dibekukan sementara atas pelanggaran etika/transaksi.',
      icon: Clock,
      tone: 'text-[#DC2626]',
    },
    {
      id: 'Blokir Permanen',
      title: 'Blokir Permanen Akun',
      desc: 'Menonaktifkan status akun pengguna secara permanen.',
      icon: Ban,
      tone: 'text-[#DC2626]',
    },
    {
      id: 'Pulihkan Akun (Aktif)',
      title: 'Pulihkan Status Akun (Aktif Kembali)',
      desc: 'Mencabut sanksi sebelumnya dan mengembalikan status akun menjadi Aktif.',
      icon: CheckCircle2,
      tone: 'text-[#059669]',
    },
  ];

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Tindakan Moderasi & Status Sanksi Akun"
      maxWidth="max-w-lg"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="clay-tile p-3.5 flex items-center justify-between gap-3">
          <div className="min-w-0">
            <span className="text-[11px] text-[#64748B] font-semibold">Target Pengguna</span>
            <p className="text-sm font-extrabold text-[#0F172A] truncate">{user.nama}</p>
            <p className="text-xs text-[#64748B] font-mono truncate">{user.email}</p>
          </div>
          <span className="px-2.5 py-1 text-[11px] font-bold rounded-full bg-[#FEF2F2] text-[#DC2626] border border-[#FECACA] shrink-0">
            {user.status_akun || 'Aktif'}
          </span>
        </div>

        <div>
          <label className="block text-[11px] font-bold uppercase tracking-wider text-[#64748B] mb-2">
            Pilihan Tindakan Sanksi
          </label>
          <div className="space-y-2">
            {options.map((opt) => {
              const Icon = opt.icon;
              const isSelected = sanctionType === opt.id;
              return (
                <button
                  type="button"
                  key={opt.id}
                  onClick={() => setSanctionType(opt.id)}
                  className={`w-full text-left p-3 rounded-2xl border transition flex items-start gap-3 ${
                    isSelected
                      ? 'bg-[#ECFDF5]/60 border-[#059669] shadow-clay-sm'
                      : 'bg-white border-[#E6EFEA] hover:border-[#CBD5E1]'
                  }`}
                >
                  <Icon className={`w-4 h-4 mt-0.5 shrink-0 ${opt.tone}`} />
                  <div className="flex-1">
                    <p className="text-xs font-bold text-[#0F172A]">{opt.title}</p>
                    <p className="text-[11px] text-[#64748B] mt-0.5">{opt.desc}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
            Kategori Alasan
          </label>
          <select
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full px-3.5 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] focus:outline-none focus:border-[#059669]"
          >
            <option value="Upaya transaksi bypass rekening bersama (Escrow)">
              Bypass Rekening Bersama Escrow (Ajakan Transfer Manual)
            </option>
            <option value="Pelanggaran Etika & Kejujuran Akademik (Anti-Joki)">
              Pelanggaran Integritas Akademik (Jasa Joki Tugas/Skripsi)
            </option>
            <option value="Keterlambatan ekstrem atau hasil kerja tidak sesuai">
              Keterlambatan / Hasil Kerja Tidak Sesuai Kesepakatan
            </option>
            <option value="Pemulihan akun setelah klarifikasi">
              Pemulihan Akun Setelah Klarifikasi
            </option>
          </select>
        </div>

        <div>
          <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
            Catatan Berita Acara
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Tuliskan nomor tiket laporan atau alasan terperinci..."
            className="w-full px-3.5 py-2 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] transition resize-none h-16"
          />
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#E6EFEA]">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-2xl text-xs font-bold text-[#475569] bg-[#F0F4F2] hover:bg-[#E2EBE6] transition"
          >
            Batal
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="clay-btn-primary px-5 py-2.5 text-xs"
          >
            {isSubmitting ? 'Menyimpan...' : 'Terapkan Status Akun'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
