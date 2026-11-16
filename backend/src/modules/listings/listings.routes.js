const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const {
  authenticate,
  optionalAuthenticate,
  requireAdmin,
} = require('../../middlewares/auth.middleware');
const {
  createGigSchema,
  updateGigSchema,
  updateGigStatusSchema,
  gigIdParamSchema,
  discoveryQuerySchema,
  moderateGigSchema,
} = require('./listings.validation');
const listingsController = require('./listings.controller');

const router = express.Router();

// 1. Master Kategori & Skills (FR-12, FR-23)
router.get('/categories', (req, res, next) =>
  listingsController.getCategories(req, res, next)
);

// 2. Daftar Gigs Milik Pengguna yang Sedang Login (termasuk Nonaktif)
router.get('/me', authenticate, (req, res, next) =>
  listingsController.listMyGigs(req, res, next)
);

// 3. Discovery & Hyperlocal Search (FR-25 s.d. FR-32)
router.get('/', validateRequest(discoveryQuerySchema), (req, res, next) =>
  listingsController.listDiscovery(req, res, next)
);

// 4. Detail Gig (FR-22)
router.get(
  '/:id',
  optionalAuthenticate,
  validateRequest(gigIdParamSchema),
  (req, res, next) => listingsController.getDetail(req, res, next)
);

// 5. Create Gig (FR-17, FR-18 - Semua pengguna terautentikasi dapat menerbitkan gig)
router.post('/', authenticate, validateRequest(createGigSchema), (req, res, next) =>
  listingsController.create(req, res, next)
);

// 6. Update Gig dengan Validasi Pemilik (FR-19, FR-20)
router.put('/:id', authenticate, validateRequest(updateGigSchema), (req, res, next) =>
  listingsController.update(req, res, next)
);
router.patch('/:id', authenticate, validateRequest(updateGigSchema), (req, res, next) =>
  listingsController.update(req, res, next)
);

// 7. Toggle Status Publikasi Aktif / Nonaktif (FR-20)
router.patch(
  '/:id/status',
  authenticate,
  validateRequest(updateGigStatusSchema),
  (req, res, next) => listingsController.updateStatus(req, res, next)
);

// 8. Delete Gig dengan Validasi Pemilik & Proteksi Transaksi Aktif (FR-21)
router.delete('/:id', authenticate, validateRequest(gigIdParamSchema), (req, res, next) =>
  listingsController.remove(req, res, next)
);

// 9. Moderasi Gig oleh Administrator (FR-93, Kerjaan #3)
router.patch(
  '/:id/moderation',
  authenticate,
  requireAdmin,
  validateRequest(moderateGigSchema),
  (req, res, next) => listingsController.moderate(req, res, next)
);

module.exports = router;
