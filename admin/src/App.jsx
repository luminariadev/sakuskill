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

  // Data states
  const [dashboardData, setDashboardData] = useState(null);
  const [users, setUsers] = useState([]);
  const [listings, setListings] = useState([]);
  const [disputes, setDisputes] = useState([]);
  const [reports, setReports] = useState([]);
  const [escrowData, setEscrowData] = useState(null);

  const loadAllData = useCallback(async () => {
    if (!token) return;
    setIsRefreshing(true);
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
    } finally {
      setIsRefreshing(false);
    }
  }, [token]);

  useEffect(() => {
    if (token) {
      loadAllData();
    }
  }, [token, loadAllData]);

  if (authLoading) {
    return (
      <div className="min-h-screen bg-[#070B14] flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user || !token) {
    return <LoginPage />;
  }

  // Handlers for mutations
  const handleVerifyUser = async (userId, status, notes) => {
    await adminApi.verifyUser(userId, status, notes);
    setUsers((prev) =>
      prev.map((u) =>
        u.user_id === userId
          ? {
              ...u,
              status_verifikasi: status,
              status_akun: status === 'Terverifikasi' ? 'Aktif' : 'Verifikasi Ditolak',
            }
          : u
      )
    );
    // Refresh dashboard stats
    adminApi.getDashboard().then(setDashboardData).catch(() => {});
  };

  const handleSanctionUser = async (userId, action, notes) => {
    await adminApi.sanctionUser(userId, action, notes);
    setUsers((prev) =>
      prev.map((u) =>
        u.user_id === userId
          ? {
              ...u,
              status_akun:
                action === 'Blokir Permanen'
                  ? 'Diblokir Permanen'
                  : action === 'Bekukan Akun Sementara (7 Hari)'
                  ? 'Dibekukan Sementara (7 Hari)'
                  : 'Peringatan Resmi',
            }
          : u
      )
    );
  };

  const handleModerateListing = async (listingId, action, notes) => {
    await adminApi.moderateListing(listingId, action, notes);
    const targetStatus =
      action === 'Hapus Permanen'
        ? 'Nonaktif'
        : action === 'Aktifkan Kembali'
        ? 'Aktif'
        : 'Disembunyikan Moderasi';

    setListings((prev) =>
      prev.map((g) =>
        g.listing_id === listingId ? { ...g, status: targetStatus } : g
      )
    );
    // Refresh dashboard
    adminApi.getDashboard().then(setDashboardData).catch(() => {});
  };

  const handleResolveDispute = async (caseId, verdict, notes) => {
    const res = await adminApi.resolveDispute(caseId, verdict, notes);
    // Reload escrow & disputes
    adminApi.getDisputes().then(setDisputes).catch(() => {});
    adminApi.getEscrow().then(setEscrowData).catch(() => {});
    adminApi.getDashboard().then(setDashboardData).catch(() => {});
    return res;
  };

  const handleResolveReport = async (reportId, action, notes) => {
    const res = await adminApi.resolveReport(reportId, action, notes);
    setReports((prev) =>
      prev.map((r) =>
        r.report_id === reportId ? { ...r, status_tiket: 'Selesai' } : r
      )
    );
    adminApi.getDashboard().then(setDashboardData).catch(() => {});
    return res;
  };

  const titles = {
    dashboard: 'Dasbor Operasional',
    users: 'Manajemen Pengguna & Verifikasi Mahasiswa',
    services: 'Manajemen Layanan & Anti-Joki',
    disputes: 'Sidang Mediasi & Putusan Sengketa',
    reports: 'Manajemen Laporan & Pengaduan',
    escrow: 'Monitoring Transaksi & Rekening Penampungan (Escrow)',
  };

  return (
    <div className="min-h-screen bg-[#0B1120] text-slate-100 flex">
      {/* Sidebar */}
      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        disputeCount={disputes.length || 2}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <Header
          currentTitle={titles[activeTab] || 'Dasbor'}
          onRefresh={loadAllData}
          isRefreshing={isRefreshing}
        />

        <main className="flex-1 p-8 overflow-y-auto">
          <div className="max-w-7xl mx-auto">
            {activeTab === 'dashboard' && (
              <DashboardPage
                data={dashboardData}
                setActiveTab={setActiveTab}
              />
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
            {activeTab === 'escrow' && (
              <EscrowPage escrowData={escrowData} />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

export default function App() {
  return <AppContent />;
}
