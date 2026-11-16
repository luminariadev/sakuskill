const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  checkoutPaymentSchema,
  orderIdParamSchema,
  webhookNotificationSchema,
  escrowActionSchema,
} = require('./payments.validation');
const paymentsController = require('./payments.controller');

const router = express.Router();

// Endpoint Webhook publik untuk menerima callback HTTP Notification dari Payment Gateway (Midtrans)
router.post('/webhook', validateRequest(webhookNotificationSchema), (req, res, next) =>
  paymentsController.webhook(req, res, next)
);

// Seluruh endpoint di bawah ini wajib menggunakan token autentikasi JWT
router.use(authenticate);

router.get('/', (req, res, next) => paymentsController.listMine(req, res, next));
router.get('/summary', (req, res, next) => paymentsController.listMine(req, res, next));

router.post('/checkout', validateRequest(checkoutPaymentSchema), (req, res, next) =>
  paymentsController.checkout(req, res, next)
);

router.get('/order/:orderId', validateRequest(orderIdParamSchema), (req, res, next) =>
  paymentsController.getByOrder(req, res, next)
);

router.get('/:orderId', validateRequest(orderIdParamSchema), (req, res, next) =>
  paymentsController.getByOrder(req, res, next)
);

router.post('/:orderId/simulate-pay', validateRequest(orderIdParamSchema), (req, res, next) =>
  paymentsController.simulatePay(req, res, next)
);

router.post('/:orderId/release', validateRequest(escrowActionSchema), (req, res, next) =>
  paymentsController.releaseEscrow(req, res, next)
);

router.post('/:orderId/refund', validateRequest(escrowActionSchema), (req, res, next) =>
  paymentsController.refundEscrow(req, res, next)
);

module.exports = router;