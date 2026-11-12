const env = require('../config/env');

const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'ENDPOINT_NOT_FOUND',
      message: 'Endpoint ' + req.method + ' ' + req.originalUrl + ' tidak ditemukan pada server SakuSkill.',
      details: null,
    },
  });
};

const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const errorCode = err.code || 'INTERNAL_SERVER_ERROR';

  console.error('[ERROR][' + new Date().toISOString() + '] ' + req.method + ' ' + req.originalUrl + ':', {
    code: errorCode,
    message: err.message,
    stack: env.nodeEnv === 'development' ? err.stack : undefined,
  });

  res.status(statusCode).json({
    success: false,
    error: {
      code: errorCode,
      message: err.isOperational
        ? err.message
        : 'Terjadi kesalahan internal pada server. Silakan coba beberapa saat lagi.',
      details: err.details || null,
    },
  });
};

module.exports = { notFoundHandler, errorHandler };
