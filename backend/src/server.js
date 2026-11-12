const app = require('./app');
const env = require('./config/env');
const { pool } = require('./config/database');

const server = app.listen(env.port, () => {
  console.log('[SERVER] SakuSkill API berjalan pada http://localhost:' + env.port + env.apiPrefix);
  console.log('[SERVER] Health-check endpoint: http://localhost:' + env.port + env.apiPrefix + '/health');
});

const shutdown = async (signal) => {
  console.log('\n[SERVER] Menerima sinyal ' + signal + '. Menutup server dan koneksi PostgreSQL...');
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
