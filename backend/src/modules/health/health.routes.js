const express = require('express');
const healthController = require('./health.controller');

const router = express.Router();

router.get('/', (req, res, next) => healthController.check(req, res, next));

module.exports = router;
