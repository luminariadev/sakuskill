const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  createOrderSchema,
  orderIdParamSchema,
  createProposalSchema,
  acceptOrderSchema,
  reasonBodySchema,
  updateOrderStatusSchema,
  createOrderReviewSchema,
} = require('./orders.validation');
const ordersController = require('./orders.controller');

const router = express.Router();

router.use(authenticate);

router.post('/', validateRequest(createOrderSchema), (req, res, next) =>
  ordersController.create(req, res, next)
);

router.get('/', (req, res, next) => ordersController.listMine(req, res, next));

router.get('/:id', validateRequest(orderIdParamSchema), (req, res, next) =>
  ordersController.getDetail(req, res, next)
);

router.post('/:id/proposals', validateRequest(createProposalSchema), (req, res, next) =>
  ordersController.propose(req, res, next)
);

router.post('/:id/accept', validateRequest(acceptOrderSchema), (req, res, next) =>
  ordersController.accept(req, res, next)
);

router.post('/:id/reject', validateRequest(reasonBodySchema), (req, res, next) =>
  ordersController.reject(req, res, next)
);

router.post('/:id/start', validateRequest(orderIdParamSchema), (req, res, next) =>
  ordersController.startWork(req, res, next)
);

router.post('/:id/request-completion', validateRequest(orderIdParamSchema), (req, res, next) =>
  ordersController.requestCompletion(req, res, next)
);

router.post('/:id/complete', validateRequest(orderIdParamSchema), (req, res, next) =>
  ordersController.complete(req, res, next)
);

router.post('/:id/cancel', validateRequest(reasonBodySchema), (req, res, next) =>
  ordersController.cancel(req, res, next)
);

router.patch('/:id/status', validateRequest(updateOrderStatusSchema), (req, res, next) =>
  ordersController.updateStatusGeneric(req, res, next)
);

router.post('/:id/reviews', validateRequest(createOrderReviewSchema), (req, res, next) =>
  ordersController.createReview(req, res, next)
);

module.exports = router;