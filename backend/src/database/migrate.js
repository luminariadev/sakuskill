const fs = require('fs');
const path = require('path');
const { pool } = require('../config/database');

async function runMigrations() {
  const client = await pool.connect();
  try {
    console.log('[MIGRATION] Memulai migrasi database SakuSkill...');

    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        filename VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    const migrationsDir = path.resolve(__dirname, '../../migrations');
    const files = fs
      .readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    // Lindungi DB yang sudah aktif sebelum adanya schema_migrations agar skrip
    // rebuild awal (003/004 yang berisi DROP TABLE) tidak menghapus data nyata.
    const { rows: appliedRows } = await client.query('SELECT filename FROM schema_migrations');
    if (appliedRows.length === 0) {
      const { rows: tableCheck } = await client.query(`
        SELECT
          to_regclass('public.users') AS has_users,
          to_regclass('public.orders') AS has_orders,
          to_regclass('public.payments') AS has_payments
      `);
      const t = tableCheck[0];
      if (t?.has_users && t?.has_orders && t?.has_payments) {
        for (const f of files) {
          if (f < '007_') {
            await client.query(
              'INSERT INTO schema_migrations (filename) VALUES ($1) ON CONFLICT (filename) DO NOTHING',
              [f]
            );
            console.log('[MIGRATION] Menandai skema eksisting sudah terpasang: ' + f);
          }
        }
      }
    }

    for (const file of files) {
      const { rows: already } = await client.query(
        'SELECT 1 FROM schema_migrations WHERE filename = $1 LIMIT 1',
        [file]
      );
      if (already.length > 0) {
        console.log('[MIGRATION] Lewati (sudah diterapkan): ' + file);
        continue;
      }

      const rawSql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
      const cleanSql = rawSql.replace(/^\uFEFF/, '').trim();
      await client.query(cleanSql);
      await client.query(
        'INSERT INTO schema_migrations (filename) VALUES ($1) ON CONFLICT (filename) DO NOTHING',
        [file]
      );
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
