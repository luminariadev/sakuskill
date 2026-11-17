import React from 'react';
import { ArrowUpRight, ArrowDownRight, Minus } from 'lucide-react';

export function KpiCard({ title, value, subtext, trend, icon: Icon, color = 'emerald' }) {
  const getTrendBadge = () => {
    if (trend === 'up') {
      return (
        <span className="flex items-center text-xs font-semibold text-emerald-400 bg-emerald-950/50 px-2 py-0.5 rounded-full border border-emerald-800/40">
          <ArrowUpRight className="w-3 h-3 mr-0.5" />
          {subtext}
        </span>
      );
    }
    if (trend === 'danger') {
      return (
        <span className="flex items-center text-xs font-semibold text-rose-400 bg-rose-950/50 px-2 py-0.5 rounded-full border border-rose-800/40">
          <ArrowDownRight className="w-3 h-3 mr-0.5" />
          {subtext}
        </span>
      );
    }
    return (
      <span className="flex items-center text-xs font-medium text-slate-400 bg-slate-800/50 px-2 py-0.5 rounded-full border border-slate-700">
        <Minus className="w-3 h-3 mr-0.5" />
        {subtext}
      </span>
    );
  };

  return (
    <div className="bg-[#111827] border border-slate-800/80 rounded-2xl p-5 hover:border-slate-700 transition shadow-lg relative overflow-hidden group">
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-medium uppercase tracking-wider text-slate-400">{title}</span>
        {Icon && (
          <div className="w-9 h-9 rounded-xl bg-slate-800/60 border border-slate-700/60 flex items-center justify-center text-emerald-400 group-hover:scale-110 transition">
            <Icon className="w-4 h-4" />
          </div>
        )}
      </div>
      <div className="text-2xl font-bold text-white tracking-tight mb-2">{value}</div>
      <div className="flex items-center">{getTrendBadge()}</div>
    </div>
  );
}
