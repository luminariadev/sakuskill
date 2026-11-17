import React, { useState } from 'react';
import { Modal } from './Modal';
import { CheckCircle2, XCircle, AlertCircle, ShieldCheck, GraduationCap } from 'lucide-react';

export function KtmModal({ isOpen, onClose, user, onVerify }) {
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!user) return null;

  const handleAction = async (status) => {
    setIsSubmitting(true);
    try {
      await onVerify(user.user_id, status, notes);
      onClose();
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Peninjauan Kartu Tanda Mahasiswa (KTM)" maxWidth="max-w-2xl">
      <div className="space-y-6">
        {/* Info Mahasiswa */}
        <div className="flex items-start gap-4 p-4 rounded-xl bg-slate-900/80 border border-slate-800">
          <div className="w-12 h-12 rounded-xl bg-emerald-950 border border-emerald-700/50 flex items-center justify-center text-emerald-400 shrink-0">
            <GraduationCap className="w-6 h-6" />
          </div>
          <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
            <div>
              <span className="text-slate-400">Nama Mahasiswa:</span>
              <p className="font-semibold text-white text-sm">{user.nama}</p>
            </div>
            <div>
              <span className="text-slate-400">NIM:</span>
              <p className="font-mono font-bold text-emerald-400">{user.nim || '2401882'}</p>
            </div>
            <div>
              <span className="text-slate-400">Program Studi:</span>
              <p className="font-medium text-slate-200">{user.program_studi || 'Pendidikan Multimedia'}</p>
            </div>
            <div>
              <span className="text-slate-400">Kampus:</span>
              <p className="font-medium text-slate-200">UPI Kampus Cibiru</p>
            </div>
          </div>
        </div>

        {/* Visual Preview Dokumen KTM */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
            Dokumen Fisik KTM Terunggah
          </label>
          <div className="relative rounded-2xl overflow-hidden border border-slate-700 bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-950/40 p-5 shadow-inner">
            {/* Visual Header Kartu */}
            <div className="flex items-center justify-between pb-3 border-b border-slate-700/60 mb-4">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-full bg-emerald-500/20 border border-emerald-400 flex items-center justify-center">
                  <span className="text-[10px] font-bold text-emerald-400">UPI</span>
                </div>
                <div>
                  <p className="text-[11px] font-bold text-white tracking-wider">KARTU MAHASISWA</p>
                  <p className="text-[9px] text-slate-400">Universitas Pendidikan Indonesia - Kampus Cibiru</p>
                </div>
              </div>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                VERIFIKASI MANUAL
              </span>
            </div>

            {/* Konten Kartu */}
            <div className="flex gap-4">
              <div className="w-28 h-36 rounded-lg bg-slate-950 border border-slate-700 overflow-hidden shrink-0 relative">
                <img
                  src={user.foto_ktm_url || 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80'}
                  alt="Foto Mahasiswa"
                  className="w-full h-full object-cover"
                />
                <div className="absolute bottom-0 inset-x-0 bg-black/60 text-[9px] text-center text-slate-300 py-0.5">
                  Foto Resmi
                </div>
              </div>
              <div className="space-y-2 text-xs flex-1">
                <div>
                  <span className="text-[10px] text-slate-400 uppercase">Nama Lengkap</span>
                  <p className="font-bold text-white">{user.nama}</p>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 uppercase">Nomor Induk Mahasiswa</span>
                  <p className="font-mono font-semibold text-emerald-300 tracking-wider">{user.nim || '2401882'}</p>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 uppercase">Departemen / Program Studi</span>
                  <p className="text-slate-300">{user.program_studi || 'Pendidikan Multimedia'}</p>
                </div>
                <div className="pt-2 flex items-center gap-1.5 text-[10px] text-emerald-400">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  <span>Format dan nomor induk terdaftar di PDDIKTI Kampus</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Catatan Admin */}
        <div>
          <label className="block text-xs font-semibold text-slate-300 mb-1.5">
            Catatan Peninjauan Administrator (Opsional)
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Misal: Dokumen KTM asli valid sesuai database mahasiswa aktif UPI Cibiru."
            className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900 border border-slate-700 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition resize-none h-20"
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
            type="button"
            onClick={() => handleAction('Ditolak')}
            disabled={isSubmitting}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold text-rose-300 bg-rose-950/60 border border-rose-700/50 hover:bg-rose-900/80 transition disabled:opacity-50"
          >
            <XCircle className="w-4 h-4" />
            Tolak Verifikasi
          </button>
          <button
            type="button"
            onClick={() => handleAction('Terverifikasi')}
            disabled={isSubmitting}
            className="flex items-center gap-1.5 px-5 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 transition shadow-lg shadow-emerald-950/50 disabled:opacity-50"
          >
            <CheckCircle2 className="w-4 h-4" />
            Verifikasi & Setujui
          </button>
        </div>
      </div>
    </Modal>
  );
}
