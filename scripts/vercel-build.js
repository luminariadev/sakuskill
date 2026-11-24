const fs = require('fs');
const path = require('path');
const { execSync, execFileSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
const adminDistDir = path.join(rootDir, 'admin', 'dist');
const vercelPublicDir = path.join(rootDir, 'vercel-public');
const vercelAdminDir = path.join(vercelPublicDir, 'admin');

console.log('[VERCEL_BUILD] Membangun Web Admin (admin/dist)...');
execSync('npm --prefix admin run build', { cwd: rootDir, stdio: 'inherit' });

if (!fs.existsSync(adminDistDir)) {
  throw new Error('Hasil build admin/dist tidak ditemukan.');
}

fs.rmSync(vercelPublicDir, { recursive: true, force: true });
fs.mkdirSync(vercelAdminDir, { recursive: true });
fs.cpSync(adminDistDir, vercelAdminDir, { recursive: true });
console.log('[VERCEL_BUILD] Aset statis Web Admin siap di vercel-public/admin.');

const databaseUrl = (process.env.DATABASE_URL || '').trim();
if (databaseUrl) {
  console.log('[VERCEL_BUILD] DATABASE_URL terdeteksi. Menjalankan migrasi database 001..007...');
  execFileSync(
    process.execPath,
    [path.join(rootDir, 'backend', 'src', 'database', 'migrate.js')],
    { cwd: rootDir, stdio: 'inherit' }
  );
  console.log('[VERCEL_BUILD] Migrasi database selesai.');
} else {
  console.log('[VERCEL_BUILD] DATABASE_URL belum disetel; langkah migrasi database dilewati.');
}
