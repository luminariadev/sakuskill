const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate, requireAdmin } = require('../../middlewares/auth.middleware');
const {
  createReportSchema,
  reportIdParamSchema,
  updateReportStatusSchema,
} = require('./reports.validation');
const reportsController = require('./reports.controller');

const router = express.Router();

router.use(authenticate);

// 1. Submit complaint / report (FR-33, FR-95)
router.post('/', validateRequest(createReportSchema), (req, res, next) =>
  reportsController.create(req, res, next)
);

// 2. List my submitted reports
router.get('/', (req, res, next) => reportsController.listMine(req, res, next));

// 3. Admin list all reports
router.get('/all', requireAdmin, (req, res, next) =>
  reportsController.listAdmin(req, res, next)
);

// 4. Detail report
router.get('/:id', validateRequest(reportIdParamSchema), (req, res, next) =>
  reportsController.getDetail(req, res, next)
);

// 5. Admin resolve report
router.patch(
  '/:id/resolve',
  requireAdmin,
  validateRequest(updateReportStatusSchema),
  (req, res, next) => reportsController.resolve(req, res, next)
);

module.exports = router;
