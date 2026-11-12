const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'sakuskill_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
  },
  hyperlocal: {
    defaultLat: parseFloat(process.env.DEFAULT_CAMPUS_LAT || '-6.9311'),
    defaultLng: parseFloat(process.env.DEFAULT_CAMPUS_LNG || '107.7175'),
    defaultRadiusMeters: parseInt(process.env.DEFAULT_HYPERLOCAL_RADIUS_METERS || '3000', 10),
  },
};

module.exports = env;
