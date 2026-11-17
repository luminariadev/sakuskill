import React, { useState } from 'react';
import { Modal } from './Modal';
import { AlertOctagon, ShieldAlert, EyeOff, Trash2, BellRing, Check } from 'lucide-react';

export function GigModerationModal({ isOpen, onClose, gig, onModerate }) {
  const [action, setAction] = useState('Takedown Segera');
  const [notes, setNotes] = useState(
    'Pelanggaran Kode Etik Mahasiswa UPI Cibiru & Kebijakan Integritas Akademik Platform SakuSkill.'
  );
  const [isSubmitting, setIsSubmitting] = useState(false);

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

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Penegakan Kebijakan Integritas Akademik (Anti-Joki)"
      maxWidth="max-w-lg"
    >
      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Banner Anti-Joki */}
        <div className="p-4 rounded-xl bg-rose-950/40 border border-rose-600/50 flex items-start gap-3">
          <AlertOctagon className="w-5 h-5 text-rose-400 shrink-0 mt-0.5" />
          <div className="text-xs">
            <p className="font-bold text-rose-300">Indikasi Pelanggaran Akademik Serius</p>
            <p className="text-slate-300 mt-1 leading-relaxed">
              Platform SakuSkill melarang keras jasa pembuatan tugas, skripsi, atau makalah
              pengganti peran mahasiswa (joki) sesuai Peraturan Rektor tentang Etika Akademik.
            </p>
          </div>
        </div>

        {/* Info Listing */}
        <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800 space-y-1 text-xs">
          <div className="flex items-center justify-between text-slate-400">
            <span>ID Listing: #{gig.listing_id}</span>
            <span className="text-emerald-400 font-semibold">{gig.kategori}</span>
          </div>
          <p className="font-bold text-white text-sm">{gig.judul}</p>
          <p className="text-slate-400">Penyedia: <span className="text-slate-200">{gig.penyedia_nama}</span></p>
        </div>

        {/* Pilihan Tindakan */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
            Tindakan Moderasi Segera
          </label>
          <div className="space-y-2">
            {[
              {
                id: 'Takedown Segera',
                title: 'Takedown Segera (Disembunyikan dari Publik)',
                desc: 'Listing disembunyikan seketika dari hasil pencarian dan katalog discovery.',
                icon: EyeOff,
              },
              {
                id: 'Peringatan Penyedia',
                title: 'Kirim Peringatan Keras ke Penyedia',
                desc: 'Listing disembunyikan dan penyedia menerima catatan pelanggaran kode etik.',
                icon: BellRing,
              },
              {
                id: 'Hapus Permanen',
                title: 'Hapus Permanen dari Basis Data',
                desc: 'Data gig dinonaktifkan secara permanen.',
                icon: Trash2,
              },
            ].map((opt) => {
              const Icon = opt.icon;
              const isSelected = action === opt.id;
              return (
                <div
                  key={opt.id}
                  onClick={() => setAction(opt.id)}
                  className={`p-3 rounded-xl border cursor-pointer transition flex items-center justify-between ${
                    isSelected
                      ? 'bg-rose-950/30 border-rose-500 text-white'
                      : 'bg-slate-900/50 border-slate-800 text-slate-400 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className={`w-4 h-4 ${isSelected ? 'text-rose-400' : 'text-slate-500'}`} />
                    <div>
                      <p className="text-xs font-bold text-white">{opt.title}</p>
                      <p className="text-[11px] text-slate-400">{opt.desc}</p>
                    </div>
                  </div>
                  {isSelected && <Check className="w-4 h-4 text-rose-400 shrink-0" />}
                </div>
              );
            })}
          </div>
        </div>

        {/* Alasan & Catatan */}
        <div>
          <label className="block text-xs font-semibold text-slate-300 mb-1.5">
            Berita Acara Moderasi
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-rose-500 transition resize-none h-20"
          ></textarea>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
          <button
            type="button"
            onClick={onClose}
            disabled={isSubmitting}
            className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white hover:bg-slate-800 transition"
          >
            Batal
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="flex items-center gap-1.5 px-5 py-2 rounded-xl text-xs font-bold text-white bg-rose-600 hover:bg-rose-500 transition shadow-lg shadow-rose-950/40 disabled:opacity-50"
          >
            <ShieldAlert className="w-4 h-4" />
            Eksekusi Moderasi Listing
          </button>
        </div>
      </form>
    </Modal>
  );
}
