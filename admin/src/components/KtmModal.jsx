import React, { useState } from 'react';
import { Modal } from './Modal';
import { UserAvatar } from './UserAvatar';
import { CheckCircle2, XCircle, ShieldCheck, GraduationCap } from 'lucide-react';

export function KtmModal({ isOpen, onClose, user, onVerify }) {
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!user) return null;

  const handleAction = async (status) => {
    setIsSubmitting(true);
    try {
      await onVerify(user.user_id, status, notes);
      setNotes('');
      onClose();
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Peninjauan Identitas & Verifikasi Mahasiswa"
      maxWidth="max-w-2xl"
    >
      <div className="space-y-5">
        <div className="clay-tile p-4 flex items-center gap-4">
          <UserAvatar
            name={user.nama}
            photoUrl={user.foto_profil}
            sizeClass="w-16 h-16 text-lg"
          />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 text-xs flex-1 min-w-0">
            <div>
              <span className="text-[#64748B] font-medium">Nama Lengkap</span>
              <p className="font-extrabold text-[#0F172A] text-sm truncate">{user.nama}</p>
            </div>
            <div>
              <span className="text-[#64748B] font-medium">Email Kampus / Aktif</span>
              <p className="font-mono font-semibold text-[#059669] truncate">{user.email}</p>
            </div>
            <div>
              <span className="text-[#64748B] font-medium">Peran Akun</span>
              <p className="font-semibold text-[#0F172A]">{user.peran || 'Penyedia Jasa'}</p>
            </div>
            <div>
              <span className="text-[#64748B] font-medium">Kampus</span>
              <p className="font-semibold text-[#0F172A]">
                {user.kampus || 'UIN Sunan Gunung Djati Bandung (Kampus Cibiru)'}
              </p>
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-[#DCE5E0] bg-[#F7FAF8] p-4 space-y-2.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold text-[#0F172A]">
              <GraduationCap className="w-4 h-4 text-[#059669]" />
              <span>Bio & Informasi Profil dari Aplikasi Mobile</span>
            </div>
            <span className="px-2.5 py-0.5 rounded-full text-[10.5px] font-bold bg-[#ECFDF5] text-[#047857] border border-[#A7F3D0]">
              {user.status_verifikasi}
            </span>
          </div>
          <p className="text-xs text-[#475569] leading-relaxed bg-white rounded-xl p-3 border border-[#E6EFEA]">
            {user.deskripsi_profil?.trim()
              ? user.deskripsi_profil
              : 'Pengguna belum menambahkan bio singkat di aplikasi mobile.'}
          </p>
          <div className="flex items-center gap-2 text-[11px] text-[#047857] font-medium pt-0.5">
            <ShieldCheck className="w-4 h-4 shrink-0" />
            <span>
              Transaksi tercatat: {user.jumlah_order || 0} order berbayar ·{' '}
              {user.jumlah_barter || 0} smart barter · {user.jumlah_layanan || 0} layanan aktif.
            </span>
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
            Catatan Peninjauan Administrator (Opsional)
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Misal: Identitas mahasiswa UIN Sunan Gunung Djati Bandung telah diverifikasi."
            className="w-full px-3.5 py-2.5 rounded-2xl bg-white border border-[#DCE5E0] text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] transition resize-none h-20"
          />
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#E6EFEA]">
          <button
            type="button"
            disabled={isSubmitting}
            onClick={() => handleAction('Ditolak')}
            className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-2xl text-xs font-bold text-[#DC2626] bg-[#FEF2F2] hover:bg-[#FEE2E2] border border-[#FECACA] transition disabled:opacity-50"
          >
            <XCircle className="w-4 h-4" />
            <span>Tolak Verifikasi</span>
          </button>
          <button
            type="button"
            disabled={isSubmitting}
            onClick={() => handleAction('Terverifikasi')}
            className="clay-btn-primary inline-flex items-center gap-1.5 px-5 py-2.5 text-xs"
          >
            <CheckCircle2 className="w-4 h-4" />
            <span>Setujui Terverifikasi</span>
          </button>
        </div>
      </div>
    </Modal>
  );
}
