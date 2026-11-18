# SakuSkill Monorepo

> Platform Marketplace Jasa Mikro Lokal dan Barter Jasa Berbasis Keterampilan Antar-Mahasiswa dan Warga Sekitar Kampus.

---

## 📌 Status Repositori & Cabang
- **`main`**: Cabang rilis utama (versi bersih dan stabil).
- **`develop`**: Cabang aktif integrasi seluruh fitur Monorepo (FE, BE, QA).
- **[`referensi`](https://github.com/luminariadev/sakuskill/tree/referensi)**: Cabang arsip yang menyimpan seluruh kode awal, blueprint arsitektur, dan implementasi sebelumnya sebagai rujukan teknis.

---

## 🏗️ Struktur Direktori Monorepo
```text
sakuskill/
├── mobile/         # Aplikasi klien Flutter + Dart (Mobile App)
├── admin/          # Web Admin Panel React 18 + Vite (Dashboard Moderasi & Escrow)
├── backend/        # REST API Node.js + Express & migrasi PostgreSQL/PostGIS (Backend)
├── docs/           # Dokumen SKPL, ERD Ringkas, API Contract, dan Pengujian
│   ├── API_CONTRACT.md
│   ├── ERD_RINGKAS.md
│   └── qa/         # Dokumen Test Plan, Test Cases, & Bug Report Template
└── .github/        # Konfigurasi Issue template, PR template, & CI/CD workflow
```

---

## 📋 Catatan Rilis & Changelog
Riwayat pembaruan dan versi rilis terperinci dicatat pada berkas [`CHANGELOG.md`](./CHANGELOG.md).
Rilis biner APK Android resmi dapat diunduh pada tab [GitHub Releases](https://github.com/luminariadev/sakuskill/releases).

---

## ⚙️ Cara Menjalankan Backend API & Database (Lokal)

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
*(Opsional) Untuk membersihkan data transaksi residu sebelum pengujian/demonstrasi:*
```bash
npm run db:clean
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

## 📱 Cara Menjalankan Mobile App (Frontend)

> **Prasyarat: Flutter ≥ 3.47 (versi tim: 3.50 stable, Dart 3.13+).**
> UI memakai [`material_ui`](https://pub.dev/packages/material_ui), library Material resmi tim Flutter yang dipisahkan dari framework sejak Flutter 3.47 (`package:flutter/material.dart` kini *deprecated*). Dengan Flutter lebih lama, `flutter pub get` akan gagal. Cek dengan `flutter --version`, lalu `flutter upgrade` bila perlu.

### 1. Masuk ke Direktori Mobile
```bash
cd mobile
```

### 2. Pasang Dependencies
```bash
flutter pub get
```

### 3. Jalankan Pengujian Otomatis (QA Suite)
```bash
flutter test
```
*Saat ini 64 unit & widget test lulus (per 16 Nov 2026). Mode demo tanpa backend: `flutter run --dart-define=USE_MOCK_DATA=true`.*

### 4. Jalankan Aplikasi pada Emulator / Perangkat
```bash
flutter run
```

---

## 📚 Dokumentasi Teknis Backend
- **ERD Ringkas:** Lihat [`docs/ERD_RINGKAS.md`](./docs/ERD_RINGKAS.md)
- **API Contract:** Lihat [`docs/API_CONTRACT.md`](./docs/API_CONTRACT.md)

---

## 🧪 Panduan Quality Assurance (QA) & Alur Kontribusi
1. **Aturan Cabang:** Pengembang membuat branch fitur baru dari `develop` (contoh: `feat/fe-setup` atau `feat/be-auth`).
2. **Pull Request:** Setiap integrasi wajib melalui Pull Request ke `develop` menggunakan [PR Template](.github/pull_request_template.md).
3. **Dokumentasi Pengujian:** Rencana pengujian dan matriks skenario pengujian dapat ditinjau pada:
   - [QA Test Plan](docs/qa/TEST_PLAN.md)
   - [QA Test Cases](docs/qa/TEST_CASES.md)
   - [Bug Report Template](docs/qa/BUG_REPORT_TEMPLATE.md)

---

## 📄 Lisensi
Didistribusikan di bawah lisensi [MIT](LICENSE).

<!-- Daily commit: Sun, Nov 15, 2026  01:27:00 AM -->
