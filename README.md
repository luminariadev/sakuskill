# SakuSkill Monorepo

Platform Marketplace Jasa Mikro Lokal dan Barter Jasa Berbasis Keterampilan Antar-Mahasiswa dan Warga Sekitar Kampus.

## Struktur Direktori (Branch: develop)
- `mobile/` — Aplikasi klien Flutter + Dart (Frontend)
- `backend/` — REST API Node.js + Express & migrasi PostgreSQL/PostGIS (Backend)
- `docs/` — Dokumen SKPL, ERD Ringkas (`docs/ERD_RINGKAS.md`), dan API Contract (`docs/API_CONTRACT.md`)

---

## Cara Menjalankan Backend API & Database (Lokal)

### 1. Masuk ke Direktori Backend & Siapkan Environment
```bash
cd backend
cp .env.example .env
```
*(Di Windows PowerShell gunakan: `Copy-Item .env.example .env`. Sesuaikan `DB_USER`, `DB_PASSWORD`, dan `DB_NAME` di dalam `backend/.env` bila menggunakan PostgreSQL lokal tanpa Docker).*

### 2. Nyalakan Database PostgreSQL + PostGIS
Jika menggunakan Docker Compose yang tersedia di dalam folder `backend/`:
```bash
docker compose up -d
```
Jika menggunakan PostgreSQL lokal, pastikan database kosong bernama `sakuskill_db` sudah dibuat.

### 3. Instal Dependensi & Jalankan Migrasi dari Kondisi Kosong
```bash
npm install
npm run db:migrate
```

### 4. Jalankan Server Express API
```bash
npm run dev
```
Server berjalan di `http://localhost:3000/api/v1`.

### 5. Verifikasi Endpoint Health-Check
```bash
curl -i http://localhost:3000/api/v1/health
```
Atau melalui Windows PowerShell:
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" | ConvertTo-Json -Depth 5
```

---

## Dokumentasi Teknis Backend
- **ERD Ringkas:** Lihat [`docs/ERD_RINGKAS.md`](./docs/ERD_RINGKAS.md)
- **API Contract:** Lihat [`docs/API_CONTRACT.md`](./docs/API_CONTRACT.md)
