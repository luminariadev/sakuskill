const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  rejectClientStatusOverride,
  requireSimulationEnv,
  createPaymentSchema,
  orderIdParamSchema,
  simulateActionSchema,
} = require('./payments.validation');
const paymentsController = require('./payments.controller');

const router = express.Router();

router.use(authenticate);

router.get('/', (req, res, next) => paymentsController.listMine(req, res, next));

// Kerjaan #1, #4, #5: Buat record payment (status selalu ditetapkan pending oleh backend)
router.post(
  '/',
  rejectClientStatusOverride,
  validateRequest(createPaymentSchema),
  (req, res, next) => paymentsController.initiate(req, res, next)
);

// Alias /checkout agar tetap kompatibel
router.post(
  '/checkout',
  rejectClientStatusOverride,
  validateRequest(createPaymentSchema),
  (req, res, next) => paymentsController.initiate(req, res, next)
);

// Kerjaan #2, #3, #4, #5: Action simulasi pending -> success (hanya aktif di demo/development & khusus pelanggan)
router.post(
  '/:orderId/simulate-success',
  requireSimulationEnv,
  rejectClientStatusOverride,
  validateRequest(simulateActionSchema),
  (req, res, next) => paymentsController.simulateSuccess(req, res, next)
);

// Alias /simulate-pay menuju simulateSuccess
router.post(
  '/:orderId/simulate-pay',
  requireSimulationEnv,
  rejectClientStatusOverride,
  validateRequest(simulateActionSchema),
  (req, res, next) => paymentsController.simulateSuccess(req, res, next)
);

// Kerjaan #2, #3, #4, #5, #7: Action simulasi pending -> failed (hanya aktif di demo/development & khusus pelanggan)
router.post(
  '/:orderId/simulate-failed',
  requireSimulationEnv,
  rejectClientStatusOverride,
  validateRequest(simulateActionSchema),
  (req, res, next) => paymentsController.simulateFailed(req, res, next)
);

// Kerjaan #5 & Acceptance Criteria: Tolak tegas jika client mencoba memaksa perubahan status langsung via PATCH/PUT
router.patch('/:orderId/status', (req, res, next) =>
  paymentsController.rejectDirectStatusPatch(req, res, next)
);
router.put('/:orderId/status', (req, res, next) =>
  paymentsController.rejectDirectStatusPatch(req, res, next)
);

router.get('/order/:orderId', validateRequest(orderIdParamSchema), (req, res, next) =>
  paymentsController.getByOrder(req, res, next)
);

router.get('/:orderId', validateRequest(orderIdParamSchema), (req, res, next) =>
  paymentsController.getByOrder(req, res, next)
);

module.exports = router;