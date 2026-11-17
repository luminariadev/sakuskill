const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const env = require('./config/env');
const requestLogger = require('./middlewares/logger.middleware');
const { notFoundHandler, errorHandler } = require('./middlewares/error.middleware');

const healthRoutes = require('./modules/health/health.routes');
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const listingsRoutes = require('./modules/listings/listings.routes');
const ordersRoutes = require('./modules/orders/orders.routes');
const barterRoutes = require('./modules/barter/barter.routes');
const paymentsRoutes = require('./modules/payments/payments.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(requestLogger);

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

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;