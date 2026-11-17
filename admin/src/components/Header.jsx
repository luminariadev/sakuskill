import React, { useState, useEffect } from 'react';
import { Bell, RefreshCw, ShieldCheck, ChevronRight } from 'lucide-react';

export function Header({ currentTitle, onRefresh, isRefreshing }) {
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
    <header className="h-16 bg-[#0F172A]/90 backdrop-blur border-b border-slate-800 px-8 flex items-center justify-between sticky top-0 z-30">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm">
        <span className="text-slate-400 font-medium">Portal Admin</span>
        <ChevronRight className="w-3.5 h-3.5 text-slate-500" />
        <span className="text-white font-semibold">{currentTitle}</span>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-4">
        {/* Compliance Badge */}
        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-950/50 border border-emerald-800/40 text-xs font-medium text-emerald-300">
          <ShieldCheck className="w-4 h-4 text-emerald-400" />
          <span>Simulasi Escrow (PBI Compliance)</span>
        </div>

        {/* Date Time */}
        <div className="text-xs text-slate-400 font-mono hidden lg:block">
          {currentTime}
        </div>

        {/* Refresh button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isRefreshing}
            title="Muat ulang data terkini"
            className="p-2 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-white transition border border-slate-700/60 disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin text-emerald-400' : ''}`} />
          </button>
        )}

        {/* Notification Bell */}
        <div className="relative">
          <button className="p-2 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-white transition border border-slate-700/60">
            <Bell className="w-4 h-4" />
          </button>
          <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-rose-500 ring-2 ring-[#0F172A]"></span>
        </div>
      </div>
    </header>
  );
}
