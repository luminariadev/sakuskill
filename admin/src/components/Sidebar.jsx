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
  Sparkles,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { UserAvatar } from './UserAvatar';

export function Sidebar({
  activeTab,
  setActiveTab,
  disputeCount = 0,
  reportCount = 0,
}) {
  const { user, logout } = useAuth();

  const navItems = [
    { id: 'dashboard', label: 'Dasbor Utama', icon: LayoutDashboard },
    { id: 'users', label: 'Pengguna & KTM', icon: Users },
    { id: 'services', label: 'Moderasi Jasa', icon: Briefcase },
    {
      id: 'disputes',
      label: 'Sidang Mediasi',
      icon: Scale,
      badge: disputeCount > 0 ? `${disputeCount}` : null,
      badgeTone: 'rose',
    },
    {
      id: 'reports',
      label: 'Laporan Masuk',
      icon: AlertTriangle,
      badge: reportCount > 0 ? `${reportCount}` : null,
      badgeTone: 'amber',
    },
    { id: 'escrow', label: 'Escrow & Barter', icon: ShieldCheck },
  ];

  const adminName = user?.nama || 'Administrator';
  const adminEmail = user?.email || 'admin@sakuskill.ac.id';

  return (
    <aside className="w-64 p-4 pr-0 shrink-0 hidden md:flex flex-col h-screen sticky top-0">
      <div className="glass-panel rounded-[26px] flex flex-col justify-between h-full overflow-hidden">
        <div>
          {/* Brand Header */}
          <div className="p-5 border-b border-[#E6EFEA]">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-[#10B981] to-[#047857] shadow-clay-emerald flex items-center justify-center shrink-0">
                <Sparkles className="w-5 h-5 text-white" />
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="font-extrabold text-lg text-[#0F172A] tracking-tight">
                    sakuskill.
                  </span>
                  <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-[#ECFDF5] text-[#047857] border border-[#A7F3D0]">
                    Admin
                  </span>
                </div>
                <p className="text-[11px] text-[#64748B] font-medium truncate">
                  UIN SGD Bandung · Cibiru
                </p>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <div className="p-3.5">
            <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-[#64748B] mb-2">
              Menu Operasional
            </p>
            <nav className="space-y-1.5">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeTab === item.id;
                const badgeCls =
                  item.badgeTone === 'rose'
                    ? isActive
                      ? 'bg-white/25 text-white border-white/30'
                      : 'bg-[#FEF2F2] text-[#DC2626] border-[#FECACA]'
                    : isActive
                    ? 'bg-white/25 text-white border-white/30'
                    : 'bg-[#FFFBEB] text-[#B45309] border-[#FDE68A]';

                return (
                  <button
                    key={item.id}
                    onClick={() => setActiveTab(item.id)}
                    className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-2xl text-[13px] font-semibold transition group ${
                      isActive
                        ? 'clay-btn-primary'
                        : 'text-[#475569] hover:text-[#0F172A] hover:bg-white/75'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <Icon
                        className={`w-4 h-4 shrink-0 transition ${
                          isActive ? 'text-white' : 'text-[#64748B] group-hover:text-[#059669]'
                        }`}
                      />
                      <span className="truncate">{item.label}</span>
                    </div>
                    {item.badge ? (
                      <span
                        className={`text-[10px] px-2 py-0.5 rounded-full font-bold border ${badgeCls}`}
                      >
                        {item.badge}
                      </span>
                    ) : isActive ? (
                      <ChevronRight className="w-4 h-4 text-emerald-100 shrink-0" />
                    ) : null}
                  </button>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Admin Account Card */}
        <div className="p-3.5 border-t border-[#E6EFEA] bg-white/55">
          <div className="clay-tile p-3 flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5 min-w-0">
              <UserAvatar
                name={adminName}
                photoUrl={user?.foto_profil || user?.foto_url}
                sizeClass="w-9 h-9 text-xs"
              />
              <div className="min-w-0">
                <p className="text-xs font-bold text-[#0F172A] truncate">{adminName}</p>
                <p className="text-[10.5px] text-[#64748B] truncate">{adminEmail}</p>
              </div>
            </div>
            <button
              onClick={logout}
              title="Keluar dari Portal Admin"
              className="w-8 h-8 rounded-xl text-[#64748B] hover:text-[#DC2626] hover:bg-[#FEF2F2] flex items-center justify-center transition shrink-0"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </aside>
  );
}
