import React from 'react';
import { ArrowUpRight, ArrowDownRight, Minus } from 'lucide-react';

const ICON_TONES = {
  emerald: 'from-[#ECFDF5] to-[#D1FAE5] text-[#059669] border-[#A7F3D0]',
  blue: 'from-[#EFF6FF] to-[#DBEAFE] text-[#2563EB] border-[#BFDBFE]',
  rose: 'from-[#FEF2F2] to-[#FEE2E2] text-[#DC2626] border-[#FECACA]',
  purple: 'from-[#F3E8FF] to-[#E9D5FF] text-[#7E22CE] border-[#D8B4FE]',
};

export function KpiCard({ title, value, subtext, trend, icon: Icon, color = 'emerald' }) {
  const iconTone = ICON_TONES[color] || ICON_TONES.emerald;

  const getTrendBadge = () => {
    if (trend === 'up') {
      return (
        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-[#047857] bg-[#ECFDF5] px-2.5 py-1 rounded-full border border-[#A7F3D0]">
          <ArrowUpRight className="w-3.5 h-3.5 shrink-0" />
          <span>{subtext}</span>
        </span>
      );
    }
    if (trend === 'danger') {
      return (
        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-[#DC2626] bg-[#FEF2F2] px-2.5 py-1 rounded-full border border-[#FECACA]">
          <ArrowDownRight className="w-3.5 h-3.5 shrink-0" />
          <span>{subtext}</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-[#475569] bg-[#F0F4F2] px-2.5 py-1 rounded-full border border-[#DCE5E0]">
        <Minus className="w-3.5 h-3.5 shrink-0" />
        <span>{subtext}</span>
      </span>
    );
  };

  return (
    <div className="clay-card p-5 transition duration-200 hover:-translate-y-0.5 group">
      <div className="flex items-start justify-between gap-3 mb-3">
        <span className="text-[11px] font-bold uppercase tracking-wider text-[#64748B] leading-snug">
          {title}
        </span>
        {Icon && (
          <div
            className={`w-10 h-10 rounded-2xl bg-gradient-to-br ${iconTone} border flex items-center justify-center shrink-0 shadow-clay-sm transition group-hover:scale-105`}
          >
            <Icon className="w-4 h-4" />
          </div>
        )}
      </div>
      <div className="text-2xl font-extrabold text-[#0F172A] tracking-tight tabular-nums mb-2.5">
        {value}
      </div>
      <div>{getTrendBadge()}</div>
    </div>
  );
}
