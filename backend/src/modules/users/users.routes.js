const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate, requireAdmin } = require('../../middlewares/auth.middleware');
const {
  updateProfileSchema,
  userIdParamSchema,
  verifyUserSchema,
} = require('./users.validation');
const usersController = require('./users.controller');

const router = express.Router();

// Endpoint profil milik sendiri (FR-08)
router.get('/me', authenticate, (req, res, next) => usersController.getMe(req, res, next));
router.put('/me', authenticate, validateRequest(updateProfileSchema), (req, res, next) =>
  usersController.updateMe(req, res, next)
);
router.patch('/me', authenticate, validateRequest(updateProfileSchema), (req, res, next) =>
  usersController.updateMe(req, res, next)
);

// Endpoint profil publik penyedia jasa (FR-11)
router.get('/:id', validateRequest(userIdParamSchema), (req, res, next) =>
  usersController.getPublicProfile(req, res, next)
);

// Endpoint khusus Administrator untuk verifikasi akun (FR-09, Kerjaan #3)
router.patch(
  '/:id/verification',
  authenticate,
  requireAdmin,
  validateRequest(verifyUserSchema),
  (req, res, next) => usersController.verifyUser(req, res, next)
);

module.exports = router;
