import React, { useState, useEffect } from 'react';
import { Modal } from './Modal';
import { AlertOctagon, EyeOff, Trash2, BellRing, Check, RotateCcw } from 'lucide-react';

export function GigModerationModal({ isOpen, onClose, gig, onModerate }) {
  const [action, setAction] = useState('Takedown Segera');
  const [notes, setNotes] = useState(
    'Tindakan kurasi & penegakan kebijakan platform SakuSkill UIN Sunan Gunung Djati Bandung.'
  );
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (gig) {
      setAction(gig.status === 'Aktif' ? 'Takedown Segera' : 'Aktifkan Kembali');
    }
  }, [gig]);

  if (!gig) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await onModerate(gig.listing_id, action, notes);
      onClose();
    } finally {
      setIsSubmitting(false);
    }
  };

  const options = [
    {
      id: 'Takedown Segera',
      title: 'Takedown Sementara (Disembunyikan Moderasi)',
      desc: 'Listing disembunyikan dari beranda dan pencarian aplikasi mobile.',
      icon: EyeOff,
    },
    {
      id: 'Peringatan Penyedia',
      title: 'Sembunyikan & Beri Catatan Pelanggaran Etik',
      desc: 'Menyembunyikan layanan karena terindikasi pelanggaran anti-joki.',
      icon: BellRing,
    },
    {
      id: 'Aktifkan Kembali',
      title: 'Aktifkan Kembali ke Katalog Publik',
      desc: 'Menampilkan layanan kembali agar dapat ditemukan pengguna mobile.',
      icon: RotateCcw,
    },
    {
      id: 'Hapus Permanen',
      title: 'Nonaktifkan Permanen',
      desc: 'Mengubah status layanan menjadi Nonaktif di basis data.',
      icon: Trash2,
    },
  ];

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Moderasi Layanan & Kebijakan Anti-Joki"
      maxWidth="max-w-lg"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="p-3.5 rounded-2xl bg-[#FFFBEB] border border-[#FDE68A] flex items-start gap-3">
          <AlertOctagon className="w-5 h-5 text-[#B45309] shrink-0 mt-0.5" />
          <div className="text-xs">
            <p className="font-bold text-[#92400E]">Kebijakan Integritas Akademik Kampus</p>
            <p className="text-[#78350F] mt-0.5 leading-relaxed">
              SakuSkill melarang jasa joki tugas, skripsi, atau ujian akademik. Layanan yang dimoderasi otomatis hilang dari pencarian aplikasi mobile.
            </p>
          </div>
        </div>

        <div className="clay-tile p-3.5 space-y-1 text-xs">
          <div className="flex items-center justify-between text-[#64748B]">
            <span className="font-mono">#{String(gig.listing_id).slice(0, 8).toUpperCase()}</span>
            <span className="text-[#059669] font-bold">{gig.kategori}</span>
          </div>
          <p className="font-extrabold text-[#0F172A] text-sm">{gig.judul}</p>
          <p className="text-[#475569]">
            Penyedia: <span className="font-semibold text-[#0F172A]">{gig.penyedia_nama}</span> · Status:{' '}
            <span className="font-semibold">{gig.status}</span>
          </p>
        </div>

        <div className="space-y-2">
          <label className="block text-[11px] font-bold uppercase tracking-wider text-[#64748B]">
            Pilih Tindakan Moderasi
          </label>
          {options.map((opt) => {
            const Icon = opt.icon;
            const isSelected = action === opt.id;
            return (
              <button
                type="button"
                key={opt.id}
                onClick={() => setAction(opt.id)}
                className={`w-full text-left p-3 rounded-2xl border transition flex items-center justify-between gap-3 ${
                  isSelected
                    ? 'bg-[#ECFDF5]/60 border-[#059669] shadow-clay-sm'
                    : 'bg-white border-[#E6EFEA] hover:border-[#CBD5E1]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 shrink-0 ${isSelected ? 'text-[#059669]' : 'text-[#64748B]'}`} />
                  <div>
                    <p className="text-xs font-bold text-[#0F172A]">{opt.title}</p>
                    <p className="text-[11px] text-[#64748B]">{opt.desc}</p>
                  </div>
                </div>
                {isSelected && <Check className="w-4 h-4 text-[#059669] shrink-0" />}
              </button>
            );
          })}
        </div>

        <div>
          <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
            Berita Acara Moderasi
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="w-full px-3.5 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] focus:outline-none focus:border-[#059669] transition resize-none h-20"
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
            {isSubmitting ? 'Memproses...' : 'Simpan Moderasi'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
