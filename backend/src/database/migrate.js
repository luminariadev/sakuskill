const fs = require('fs');
const path = require('path');
const { pool } = require('../config/database');

async function runMigrations() {
  const client = await pool.connect();
  try {
    console.log('[MIGRATION] Memulai migrasi database SakuSkill dari kondisi kosong...');
    const migrationFile = path.resolve(
      __dirname,
      '../../migrations/001_init_sakuskill_schema.sql'
    );
    const sql = fs.readFileSync(migrationFile, 'utf8');

    await client.query(sql);
    console.log('[MIGRATION] Sukses! Seluruh 13 tabel, enum, dan ekstensi PostGIS telah terpasang.');
  } catch (error) {
    console.error('[MIGRATION] Gagal menjalankan migrasi:', error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
