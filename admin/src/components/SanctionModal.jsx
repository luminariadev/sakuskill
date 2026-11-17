import React, { useState } from 'react';
import { Modal } from './Modal';
import { ShieldAlert, AlertTriangle, UserX, Clock, Ban } from 'lucide-react';

export function SanctionModal({ isOpen, onClose, user, onSanction }) {
  const [sanctionType, setSanctionType] = useState('Bekukan Akun Sementara (7 Hari)');
  const [reason, setReason] = useState('Upaya transaksi bypass rekening bersama (WhatsApp)');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!user) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await onSanction(user.user_id, sanctionType, `${reason}. ${notes}`);
      onClose();
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Tindakan Moderasi & Sanksi Akun" maxWidth="max-w-lg">
      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Info Pelanggar */}
        <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
          <div>
            <span className="text-[11px] text-slate-400">Target Mahasiswa</span>
            <p className="text-sm font-bold text-white">{user.nama}</p>
            <p className="text-xs text-slate-400 font-mono">NIM: {user.nim || '2104921'}</p>
          </div>
          <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-rose-950/60 text-rose-400 border border-rose-800/40">
            Terindikasi Pelanggaran
          </span>
        </div>

        {/* Pilihan Jenis Sanksi */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
            Tingkat Sanksi yang Dikenakan
          </label>
          <div className="space-y-2">
            {[
              {
                id: 'Peringatan Resmi',
                title: 'Peringatan Resmi (Tingkat 1)',
                desc: 'Mengirimkan surat teguran dan peringatan sistem via notifikasi & email.',
                icon: AlertTriangle,
                color: 'text-amber-400',
              },
              {
                id: 'Bekukan Akun Sementara (7 Hari)',
                title: 'Bekukan Akun Sementara (7 Hari)',
                desc: 'Akun tidak dapat menerbitkan gig atau menerima order selama 7 hari.',
                icon: Clock,
                color: 'text-orange-400',
              },
              {
                id: 'Blokir Permanen',
                title: 'Blokir Permanen & Blacklist NIM',
                desc: 'Akses akun dimatikan total dan NIM dimasukkan ke daftar hitam kampus.',
                icon: Ban,
                color: 'text-rose-400',
              },
            ].map((opt) => {
              const Icon = opt.icon;
              const isSelected = sanctionType === opt.id;
              return (
                <div
                  key={opt.id}
                  onClick={() => setSanctionType(opt.id)}
                  className={`p-3.5 rounded-xl border cursor-pointer transition flex items-start gap-3 ${
                    isSelected
                      ? 'bg-rose-950/20 border-rose-600/70 shadow-sm'
                      : 'bg-slate-900/60 border-slate-800 hover:border-slate-700'
                  }`}
                >
                  <div
                    className={`w-4 h-4 rounded-full border mt-0.5 flex items-center justify-center ${
                      isSelected ? 'border-rose-500 bg-rose-500' : 'border-slate-600'
                    }`}
                  >
                    {isSelected && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-1.5">
                      <Icon className={`w-3.5 h-3.5 ${opt.color}`} />
                      <p className="text-xs font-bold text-white">{opt.title}</p>
                    </div>
                    <p className="text-[11px] text-slate-400 mt-0.5">{opt.desc}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Alasan Pelanggaran */}
        <div>
          <label className="block text-xs font-semibold text-slate-300 mb-1.5">
            Kategori Pelanggaran
          </label>
          <select
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white focus:outline-none focus:border-emerald-500"
          >
            <option value="Upaya transaksi bypass rekening bersama (WhatsApp)">
              Bypass Rekening Bersama Escrow (Ajakan Transfer Manual)
            </option>
            <option value="Pelanggaran Etika & Kejujuran Akademik (Anti-Joki)">
              Pelanggaran Integritas Akademik (Jasa Joki Tugas/Skripsi)
            </option>
            <option value="Penipuan atau hasil kerja fiktif">Penipuan atau Hasil Kerja Fiktif</option>
            <option value="Spam dan pelecehan komunikasi antar-mahasiswa">
              Spam dan Pelecehan Komunikasi Chat
            </option>
          </select>
        </div>

        {/* Catatan Admin */}
        <div>
          <label className="block text-xs font-semibold text-slate-300 mb-1.5">
            Keterangan & Catatan Berita Acara
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Tuliskan nomor tiket laporan pengaduan atau bukti pelanggaran..."
            className="w-full px-3.5 py-2 rounded-xl bg-slate-900 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-rose-500 transition resize-none h-16"
          ></textarea>
        </div>

        {/* Buttons */}
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
            Terapkan Sanksi Akun
          </button>
        </div>
      </form>
    </Modal>
  );
}
