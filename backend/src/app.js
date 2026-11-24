const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const env = require('./config/env');
const requestLogger = require('./middlewares/logger.middleware');
const { globalRateLimiter } = require('./middlewares/rateLimit.middleware');
const { notFoundHandler, errorHandler } = require('./middlewares/error.middleware');

const healthRoutes = require('./modules/health/health.routes');
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const listingsRoutes = require('./modules/listings/listings.routes');
const ordersRoutes = require('./modules/orders/orders.routes');
const barterRoutes = require('./modules/barter/barter.routes');
const paymentsRoutes = require('./modules/payments/payments.routes');
const reportsRoutes = require('./modules/reports/reports.routes');
const adminRoutes = require('./modules/admin/admin.routes');

const app = express();
app.set('trust proxy', 1);

app.use(
  helmet({
    contentSecurityPolicy: false,
  })
);
app.use(cors());
app.use(globalRateLimiter);
app.use(express.json({ limit: '2mb' }));
app.use(requestLogger);

// Root status & health check untuk Render / Cloud platforms
app.get('/', (req, res) =>
  res.json({
    status: 'ok',
    service: 'sakuskill-backend',
    api: env.apiPrefix,
    admin: '/admin/',
    health: '/health',
  })
);
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'sakuskill-backend', timestamp: new Date().toISOString() }));

// Registrasi seluruh modul endpoint SakuSkill
app.use(env.apiPrefix + '/health', healthRoutes);
app.use(env.apiPrefix + '/auth', authRoutes);
app.use(env.apiPrefix + '/users', usersRoutes);
app.use(env.apiPrefix + '/profile', usersRoutes);
app.use(env.apiPrefix + '/gigs', listingsRoutes);
app.use(env.apiPrefix + '/listings', listingsRoutes);
app.use(env.apiPrefix + '/orders', ordersRoutes);
app.use(env.apiPrefix + '/barter', barterRoutes);
app.use(env.apiPrefix + '/barters', barterRoutes);
app.use(env.apiPrefix + '/payments', paymentsRoutes);
app.use(env.apiPrefix + '/escrow', paymentsRoutes);
app.use(env.apiPrefix + '/reports', reportsRoutes);
app.use(env.apiPrefix + '/admin', adminRoutes);

// Sajikan Web Admin Portal dalam 1 service yang sama di path /admin
const adminDistPath = path.resolve(__dirname, '../../admin/dist');
if (fs.existsSync(adminDistPath)) {
  app.use('/admin', (req, res, next) => {
    const cleanUrl = (req.originalUrl || '').split('?')[0];
    if (cleanUrl === '/admin') {
      res.set('Cache-Control', 'no-store');
      return res.redirect(302, '/admin/');
    }
    return next();
  });
  app.use('/admin', express.static(adminDistPath));
  app.get('/admin/*', (req, res) => {
    res.sendFile(path.join(adminDistPath, 'index.html'));
  });
}

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;