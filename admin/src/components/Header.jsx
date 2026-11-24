import React, { useState, useEffect } from 'react';
import { RefreshCw, ShieldCheck, ChevronRight, Radio } from 'lucide-react';

export function Header({ currentTitle, onRefresh, isRefreshing, lastSyncedAt }) {
  const [currentTime, setCurrentTime] = useState('');

  useEffect(() => {
    const update = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleDateString('id-ID', {
          weekday: 'short',
          day: 'numeric',
          month: 'short',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        })
      );
    };
    update();
    const interval = setInterval(update, 30000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="px-6 pt-4 pb-1 sticky top-0 z-30">
      <div className="glass-panel rounded-2xl px-6 h-16 flex items-center justify-between gap-4">
        <div className="flex items-center gap-2 text-sm min-w-0">
          <span className="text-[#64748B] font-semibold shrink-0">Portal Admin</span>
          <ChevronRight className="w-3.5 h-3.5 text-[#94A3B8] shrink-0" />
          <span className="text-[#0F172A] font-extrabold truncate">{currentTitle}</span>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <div className="hidden lg:flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#ECFDF5] border border-[#A7F3D0] text-[11px] font-bold text-[#047857]">
            <Radio className="w-3.5 h-3.5 text-[#059669] animate-pulse" />
            <span>Sinkron Real-Time DB</span>
            {lastSyncedAt && (
              <span className="text-[#64748B] font-mono font-medium">· {lastSyncedAt}</span>
            )}
          </div>

          <div className="hidden xl:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#EFF6FF] border border-[#BFDBFE] text-[11px] font-bold text-[#2563EB]">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Simulasi Escrow MVP</span>
          </div>

          <div className="text-[11px] text-[#64748B] font-mono hidden 2xl:block">
            {currentTime}
          </div>

          {onRefresh && (
            <button
              onClick={onRefresh}
              disabled={isRefreshing}
              title="Muat ulang data terkini"
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl clay-tile text-xs font-bold text-[#0F172A] hover:text-[#059669] transition disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-[#059669]' : ''}`} />
              <span className="hidden sm:inline">Segarkan</span>
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
