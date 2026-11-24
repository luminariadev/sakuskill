import React from 'react';

export function StatusBadge({ status, tone }) {
  let cls = 'bg-[#F0F4F2] text-[#475569] border-[#DDE6E1]';

  const s = String(status || '').toLowerCase();
  const t = String(tone || '').toLowerCase();

  if (
    t === 'success' ||
    s.includes('terverifikasi') ||
    s === 'aktif' ||
    s.includes('selesai') ||
    s.includes('dilepas') ||
    s.includes('tuntas')
  ) {
    cls = 'bg-[#ECFDF5] text-[#047857] border-[#A7F3D0]';
  } else if (
    t === 'danger' ||
    s.includes('sengketa') ||
    s.includes('dibekukan') ||
    s.includes('blokir') ||
    s.includes('joki') ||
    s.includes('ditolak') ||
    s.includes('dibatalkan') ||
    s.includes('batal') ||
    s.includes('nonaktif') ||
    s.includes('disembunyikan')
  ) {
    cls = 'bg-[#FEF2F2] text-[#DC2626] border-[#FECACA]';
  } else if (t === 'purple' || s.includes('barter')) {
    cls = 'bg-[#F3E8FF] text-[#7E22CE] border-[#D8B4FE]';
  } else if (
    t === 'warning' ||
    s.includes('belum terverifikasi') ||
    s.includes('menunggu') ||
    s.includes('ditinjau') ||
    s.includes('baru') ||
    s.includes('ditahan') ||
    s.includes('peringatan') ||
    s.includes('overdue') ||
    s.includes('diajukan')
  ) {
    cls = 'bg-[#FFFBEB] text-[#B45309] border-[#FDE68A]';
  } else if (
    t === 'info' ||
    s.includes('dikerjakan') ||
    s.includes('berjalan') ||
    s.includes('disepakati')
  ) {
    cls = 'bg-[#EFF6FF] text-[#2563EB] border-[#BFDBFE]';
  }

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-bold rounded-full border shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] ${cls}`}
    >
      <span className="w-1.5 h-1.5 rounded-full bg-current shrink-0"></span>
      <span>{status || '-'}</span>
    </span>
  );
}
