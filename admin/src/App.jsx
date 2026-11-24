import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from './context/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { UsersPage } from './pages/UsersPage';
import { ServicesPage } from './pages/ServicesPage';
import { DisputePage } from './pages/DisputePage';
import { ReportsPage } from './pages/ReportsPage';
import { EscrowPage } from './pages/EscrowPage';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { adminApi } from './api/adminApi';

export function AppContent() {
  const { user, token, loading: authLoading } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastSyncedAt, setLastSyncedAt] = useState('');

  const [dashboardData, setDashboardData] = useState(null);
  const [users, setUsers] = useState([]);
  const [listings, setListings] = useState([]);
  const [disputes, setDisputes] = useState([]);
  const [reports, setReports] = useState([]);
  const [escrowData, setEscrowData] = useState(null);

  const loadAllData = useCallback(
    async ({ silent = false } = {}) => {
      if (!token) return;
      if (!silent) setIsRefreshing(true);
      try {
        const [dash, u, l, d, r, e] = await Promise.allSettled([
          adminApi.getDashboard(),
          adminApi.getUsers(),
          adminApi.getListings(),
          adminApi.getDisputes(),
          adminApi.getReports(),
          adminApi.getEscrow(),
        ]);

        if (dash.status === 'fulfilled') setDashboardData(dash.value);
        if (u.status === 'fulfilled') setUsers(u.value);
        if (l.status === 'fulfilled') setListings(l.value);
        if (d.status === 'fulfilled') setDisputes(d.value);
        if (r.status === 'fulfilled') setReports(r.value);
        if (e.status === 'fulfilled') setEscrowData(e.value);

        setLastSyncedAt(
          new Date().toLocaleTimeString('id-ID', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
          })
        );
      } finally {
        if (!silent) setIsRefreshing(false);
      }
    },
    [token]
  );

  useEffect(() => {
    if (!token) return;
    loadAllData();
    const timer = setInterval(() => {
      if (document.visibilityState === 'visible') {
        loadAllData({ silent: true });
      }
    }, 15000);
    return () => clearInterval(timer);
  }, [token, loadAllData]);

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-9 h-9 border-4 border-[#059669] border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user || !token) {
    return <LoginPage />;
  }

  const handleVerifyUser = async (userId, status, notes) => {
    await adminApi.verifyUser(userId, status, notes);
    await loadAllData({ silent: true });
  };

  const handleSanctionUser = async (userId, action, notes) => {
    await adminApi.sanctionUser(userId, action, notes);
    await loadAllData({ silent: true });
  };

  const handleModerateListing = async (listingId, action, notes) => {
    await adminApi.moderateListing(listingId, action, notes);
    await loadAllData({ silent: true });
  };

  const handleResolveDispute = async (caseId, verdict, notes) => {
    const res = await adminApi.resolveDispute(caseId, verdict, notes);
    await loadAllData({ silent: true });
    return res;
  };

  const handleResolveReport = async (reportId, action, notes) => {
    const res = await adminApi.resolveReport(reportId, action, notes);
    await loadAllData({ silent: true });
    return res;
  };

  const openReportCount = reports.filter((r) => r.status_penanganan !== 'Selesai').length;

  const titles = {
    dashboard: 'Dasbor Operasional Kampus',
    users: 'Pengguna & Verifikasi Identitas',
    services: 'Moderasi Layanan & Anti-Joki',
    disputes: 'Sidang Mediasi & Arbitrase',
    reports: 'Manajemen Laporan & Komplain',
    escrow: 'Monitoring Escrow & Smart Barter',
  };

  const mobileTabs = [
    { id: 'dashboard', label: 'Dasbor' },
    { id: 'users', label: 'Pengguna' },
    { id: 'services', label: 'Layanan' },
    { id: 'disputes', label: 'Mediasi' },
    { id: 'reports', label: 'Laporan' },
    { id: 'escrow', label: 'Escrow' },
  ];

  return (
    <div className="min-h-screen flex">
      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        disputeCount={disputes.length}
        reportCount={openReportCount}
      />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          currentTitle={titles[activeTab] || 'Dasbor'}
          onRefresh={() => loadAllData()}
          isRefreshing={isRefreshing}
          lastSyncedAt={lastSyncedAt}
        />

        {/* Compact tablet/mobile tab switcher */}
        <div className="px-6 pt-3 flex md:hidden items-center gap-1.5 overflow-x-auto">
          {mobileTabs.map((t) => (
            <button
              key={t.id}
              onClick={() => setActiveTab(t.id)}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition shrink-0 ${
                activeTab === t.id
                  ? 'clay-btn-primary'
                  : 'clay-tile text-[#475569]'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        <main className="flex-1 px-6 py-5 overflow-y-auto">
          <div className="max-w-7xl mx-auto">
            {activeTab === 'dashboard' && (
              <DashboardPage data={dashboardData} setActiveTab={setActiveTab} />
            )}
            {activeTab === 'users' && (
              <UsersPage
                users={users}
                onVerifyUser={handleVerifyUser}
                onSanctionUser={handleSanctionUser}
              />
            )}
            {activeTab === 'services' && (
              <ServicesPage
                listings={listings}
                onModerateListing={handleModerateListing}
              />
            )}
            {activeTab === 'disputes' && (
              <DisputePage
                disputes={disputes}
                onResolveDispute={handleResolveDispute}
              />
            )}
            {activeTab === 'reports' && (
              <ReportsPage
                reports={reports}
                onResolveReport={handleResolveReport}
              />
            )}
            {activeTab === 'escrow' && <EscrowPage escrowData={escrowData} />}
          </div>
        </main>
      </div>
    </div>
  );
}

export default function App() {
  return <AppContent />;
}
