const { Pool } = require('pg');
const env = require('./env');

const connectionString = process.env.DATABASE_URL;
const isProduction = env.nodeEnv === 'production';
const needsSsl = connectionString?.includes('sslmode=require') || connectionString?.includes('neon.tech') || connectionString?.includes('supabase.co') || connectionString?.includes('supabase.com') || isProduction;

const poolConfig = connectionString
  ? {
      connectionString,
      ssl: needsSsl ? { rejectUnauthorized: false } : false,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 15000,
    }
  : {
      host: env.db.host,
      port: env.db.port,
      database: env.db.database,
      user: env.db.user,
      password: env.db.password,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    };

const pool = new Pool(poolConfig);

pool.on('error', (err) => {
  console.error('[DB_ERROR] Kesalahan tak terduga pada idle client PostgreSQL:', err.message);
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
