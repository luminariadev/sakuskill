const express = require('express');
const { authenticate, requireAdmin } = require('../../middlewares/auth.middleware');
const adminController = require('./admin.controller');

const router = express.Router();

// Seluruh endpoint admin diproteksi dengan otentikasi JWT & peran Administrator
router.use(authenticate, requireAdmin);

// 1. Dasbor Operasional (KPIs, SLA Alert, Aktivitas)
router.get('/dashboard', (req, res, next) => adminController.getDashboard(req, res, next));

// 2. Manajemen Pengguna & Verifikasi KTM
router.get('/users', (req, res, next) => adminController.getUsers(req, res, next));
router.patch('/users/:id/verification', (req, res, next) => adminController.verifyUser(req, res, next));
router.patch('/users/:id/sanction', (req, res, next) => adminController.sanctionUser(req, res, next));

// 3. Manajemen Layanan & Anti-Joki (Academic Integrity)
router.get('/listings', (req, res, next) => adminController.getListings(req, res, next));
router.patch('/listings/:id/moderation', (req, res, next) => adminController.moderateListing(req, res, next));

// 4. Sidang Mediasi & Putusan Sengketa
router.get('/disputes', (req, res, next) => adminController.getDisputes(req, res, next));
router.post('/disputes/:id/verdict', (req, res, next) => adminController.resolveDispute(req, res, next));

// 5. Manajemen Laporan & Pengaduan (Bypass Escrow, dll)
router.get('/reports', (req, res, next) => adminController.getReports(req, res, next));
router.patch('/reports/:id/action', (req, res, next) => adminController.resolveReport(req, res, next));

// 6. Monitoring Transaksi & Escrow
router.get('/escrow', (req, res, next) => adminController.getEscrowTransactions(req, res, next));

module.exports = router;
