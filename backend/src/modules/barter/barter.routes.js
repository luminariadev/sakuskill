const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const {
  createBarterSchema,
  barterIdParamSchema,
  updateBarterTermsSchema,
  confirmBarterCompletionSchema,
  barterReasonSchema,
  updateBarterStatusSchema,
  createBarterReviewSchema,
  createBarterMessageSchema,
} = require('./barter.validation');
const barterController = require('./barter.controller');

const router = express.Router();

router.use(authenticate);

router.post('/', validateRequest(createBarterSchema), (req, res, next) =>
  barterController.create(req, res, next)
);

router.get('/', (req, res, next) => barterController.listMine(req, res, next));

router.get('/:id', validateRequest(barterIdParamSchema), (req, res, next) =>
  barterController.getDetail(req, res, next)
);

router.put('/:id/terms', validateRequest(updateBarterTermsSchema), (req, res, next) =>
  barterController.updateTerms(req, res, next)
);

router.post('/:id/accept', validateRequest(barterIdParamSchema), (req, res, next) =>
  barterController.accept(req, res, next)
);

router.post('/:id/reject', validateRequest(barterReasonSchema), (req, res, next) =>
  barterController.reject(req, res, next)
);

router.post('/:id/start', validateRequest(barterIdParamSchema), (req, res, next) =>
  barterController.startWork(req, res, next)
);

router.post('/:id/confirm-completion', validateRequest(confirmBarterCompletionSchema), (req, res, next) =>
  barterController.confirmCompletion(req, res, next)
);

router.post('/:id/complete', validateRequest(confirmBarterCompletionSchema), (req, res, next) =>
  barterController.confirmCompletion(req, res, next)
);

router.post('/:id/cancel', validateRequest(barterReasonSchema), (req, res, next) =>
  barterController.cancel(req, res, next)
);

router.patch('/:id/status', validateRequest(updateBarterStatusSchema), (req, res, next) =>
  barterController.updateStatusGeneric(req, res, next)
);

router.post('/:id/reviews', validateRequest(createBarterReviewSchema), (req, res, next) =>
  barterController.createReview(req, res, next)
);

router.get('/:id/messages', validateRequest(barterIdParamSchema), (req, res, next) =>
  barterController.listMessages(req, res, next)
);

router.post('/:id/messages', validateRequest(createBarterMessageSchema), (req, res, next) =>
  barterController.sendMessage(req, res, next)
);

module.exports = router;