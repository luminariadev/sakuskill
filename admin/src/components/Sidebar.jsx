import React from 'react';
import {
  LayoutDashboard,
  Users,
  Briefcase,
  Scale,
  AlertTriangle,
  ShieldCheck,
  LogOut,
  ChevronRight,
  ShieldAlert,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export function Sidebar({ activeTab, setActiveTab, disputeCount = 2 }) {
  const { user, logout } = useAuth();

  const navItems = [
    { id: 'dashboard', label: 'Dasbor Utama', icon: LayoutDashboard },
    { id: 'users', label: 'Manajemen Pengguna', icon: Users },
    { id: 'services', label: 'Manajemen Layanan', icon: Briefcase },
    {
      id: 'disputes',
      label: 'Sidang Mediasi',
      icon: Scale,
      badge: `${disputeCount} Perkara`,
      badgeColor: 'bg-rose-500/20 text-rose-400 border-rose-500/30',
    },
    { id: 'reports', label: 'Manajemen Laporan', icon: AlertTriangle },
    { id: 'escrow', label: 'Monitoring Escrow', icon: ShieldCheck },
  ];

  return (
    <aside className="w-64 bg-[#0F172A] border-r border-slate-800 flex flex-col justify-between shrink-0 h-screen sticky top-0">
      <div>
        {/* Brand Header */}
        <div className="p-6 border-b border-slate-800/80">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center shadow-lg shadow-emerald-950/40">
              <ShieldAlert className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-base text-white tracking-wide">SakuSkill</span>
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              </div>
              <p className="text-xs text-slate-400 font-medium">Portal Admin Kampus</p>
            </div>
          </div>
        </div>

        {/* Navigation Section */}
        <div className="px-3 py-6">
          <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">
            Menu Operasional
          </p>
          <nav className="space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id)}
                  className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-medium transition group ${
                    isActive
                      ? 'bg-emerald-600 text-white shadow-md shadow-emerald-950/30'
                      : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon
                      className={`w-4 h-4 transition ${
                        isActive ? 'text-white' : 'text-slate-400 group-hover:text-emerald-400'
                      }`}
                    />
                    <span>{item.label}</span>
                  </div>
                  {item.badge ? (
                    <span
                      className={`text-[11px] px-2 py-0.5 rounded-full font-semibold border ${
                        isActive
                          ? 'bg-emerald-700/60 text-white border-emerald-500/50'
                          : item.badgeColor
                      }`}
                    >
                      {item.badge}
                    </span>
                  ) : isActive ? (
                    <ChevronRight className="w-4 h-4 text-emerald-200" />
                  ) : null}
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Admin Profile Footer */}
      <div className="p-4 border-t border-slate-800 bg-[#0c1322]">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-9 h-9 rounded-full bg-emerald-900/60 border border-emerald-600/50 flex items-center justify-center text-xs font-bold text-emerald-300 shrink-0">
              SA
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-white truncate">Super Admin</p>
              <p className="text-[11px] text-slate-400 truncate">admin@sakuskill.ac.id</p>
            </div>
          </div>
          <button
            onClick={logout}
            title="Keluar"
            className="p-2 text-slate-400 hover:text-rose-400 hover:bg-slate-800/80 rounded-lg transition"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
        <div className="mt-2.5 pt-2 border-t border-slate-800/60 flex items-center justify-between text-[10px] text-slate-400">
          <span>Role: OS Manager</span>
          <span className="text-emerald-400 font-mono">UPI Cibiru</span>
        </div>
      </div>
    </aside>
  );
}
