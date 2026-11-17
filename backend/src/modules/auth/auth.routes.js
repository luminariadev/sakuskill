const express = require('express');
const validateRequest = require('../../middlewares/validate.middleware');
const { authenticate } = require('../../middlewares/auth.middleware');
const { authRateLimiter } = require('../../middlewares/rateLimit.middleware');
const { registerSchema, loginSchema } = require('./auth.validation');
const authController = require('./auth.controller');

const router = express.Router();

router.post('/register', authRateLimiter, validateRequest(registerSchema), (req, res, next) =>
  authController.register(req, res, next)
);

router.post('/login', authRateLimiter, validateRequest(loginSchema), (req, res, next) =>
  authController.login(req, res, next)
);

router.post('/logout', authenticate, (req, res, next) =>
  authController.logout(req, res, next)
);

module.exports = router;
