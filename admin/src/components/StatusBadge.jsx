import React from 'react';

export function StatusBadge({ status, tone }) {
  let bg = 'bg-slate-800 text-slate-300 border-slate-700';

  const s = String(status || '').toLowerCase();
  const t = String(tone || '').toLowerCase();

  if (t === 'success' || s.includes('terverifikasi') || s.includes('aktif') || s.includes('selesai') || s.includes('dilepas')) {
    bg = 'bg-emerald-950/60 text-emerald-400 border-emerald-500/30';
  } else if (t === 'danger' || s.includes('sengketa') || s.includes('dibekukan') || s.includes('blokir') || s.includes('joki') || s.includes('ditolak') || s.includes('batal')) {
    bg = 'bg-rose-950/60 text-rose-400 border-rose-500/30';
  } else if (t === 'warning' || s.includes('menunggu') || s.includes('investigasi') || s.includes('tindakan') || s.includes('ditahan') || s.includes('peringatan') || s.includes('overdue')) {
    bg = 'bg-amber-950/60 text-amber-400 border-amber-500/30';
  } else if (t === 'purple' || s.includes('barter')) {
    bg = 'bg-purple-950/60 text-purple-400 border-purple-500/30';
  } else if (t === 'info' || s.includes('review') || s.includes('berjalan')) {
    bg = 'bg-blue-950/60 text-blue-400 border-blue-500/30';
  }

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full border ${bg}`}>
      <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
      {status}
    </span>
  );
}
