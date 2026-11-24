import React, { useState } from 'react';

const PALETTES = [
  'from-[#E6FBF2] to-[#C5F4DF] text-[#047857]',
  'from-[#F3EEFF] to-[#E4D9FF] text-[#6D28D9]',
  'from-[#EAF2FF] to-[#D5E5FF] text-[#1D4ED8]',
  'from-[#FFF8E1] to-[#FEF0B8] text-[#B45309]',
  'from-[#FCEEF5] to-[#FAD7E8] text-[#BE185D]',
  'from-[#E7F6FE] to-[#CBEBFD] text-[#0369A1]',
];

function getInitials(name) {
  const parts = String(name || 'S').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'S';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}

export function UserAvatar({ name, photoUrl, sizeClass = 'w-10 h-10 text-xs' }) {
  const [imgError, setImgError] = useState(false);
  const hash = String(name || '').split('').reduce((acc, ch) => acc + ch.charCodeAt(0), 0);
  const palette = PALETTES[hash % PALETTES.length];
  const hasPhoto = Boolean(photoUrl && String(photoUrl).trim() && !imgError);

  return (
    <div
      className={`${sizeClass} rounded-full bg-gradient-to-br ${palette} border-2 border-white shadow-clay-sm flex items-center justify-center font-extrabold shrink-0 overflow-hidden select-none`}
      title={name}
    >
      {hasPhoto ? (
        <img
          src={photoUrl}
          alt={name || 'Foto profil'}
          className="w-full h-full object-cover"
          onError={() => setImgError(true)}
        />
      ) : (
        <span>{getInitials(name)}</span>
      )}
    </div>
  );
}
