const fs = require('fs');
const path = require('path');
const { pool } = require('../config/database');

async function runMigrations() {
  const client = await pool.connect();
  try {
    console.log('[MIGRATION] Memulai migrasi database SakuSkill...');
    const migrationsDir = path.resolve(__dirname, '../../migrations');
    const files = fs
      .readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      const rawSql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
      const cleanSql = rawSql.replace(/^\uFEFF/, '').trim();
      await client.query(cleanSql);
      console.log('[MIGRATION] Berhasil menerapkan: ' + file);
    }

    console.log('[MIGRATION] Sukses! Seluruh skema database SakuSkill telah mutakhir.');
  } catch (error) {
    console.error('[MIGRATION] Gagal menjalankan migrasi:', error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
