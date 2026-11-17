const db = require('./src/config/database');
const bcrypt = require('bcryptjs');

async function seedAdmin() {
  const hash = await bcrypt.hash('rahasia123', 10);
  const check = await db.query('SELECT user_id, email, peran FROM users WHERE email = $1', ['admin@sakuskill.ac.id']);
  
  if (check.rows.length > 0) {
    const res = await db.query(
      'UPDATE users SET peran = $1, kata_sandi_hash = $2, status_verifikasi = $3 WHERE email = $4 RETURNING user_id, nama, email, peran',
      ['Administrator', hash, 'Terverifikasi', 'admin@sakuskill.ac.id']
    );
    console.log('Admin user updated:', res.rows[0]);
  } else {
    const res = await db.query(
      'INSERT INTO users (nama, email, kata_sandi_hash, peran, status_verifikasi, deskripsi_profil) VALUES ($1, $2, $3, $4, $5, $6) RETURNING user_id, nama, email, peran',
      ['Super Admin SakuSkill', 'admin@sakuskill.ac.id', hash, 'Administrator', 'Terverifikasi', 'Administrator Operasional & Mediasi SakuSkill UPI Cibiru']
    );
    console.log('Admin user created:', res.rows[0]);
  }
  process.exit(0);
}

seedAdmin().catch(err => {
  console.error(err);
  process.exit(1);
});
