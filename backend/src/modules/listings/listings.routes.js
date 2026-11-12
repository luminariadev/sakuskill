const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { getHyperlocalListingsSchema } = require('./listings.validation');
const listingsController = require('./listings.controller');

const router = express.Router();

router.get(
  '/',
  validateRequest(getHyperlocalListingsSchema),
  (req, res, next) => listingsController.listNearby(req, res, next)
);

module.exports = router;
