# Integrasi Frontend ↔ Backend (lokal)

> Branch `feat/fe-be-integration` (dari `develop` 6de3e36 + fondasi FE M1). Diuji 17 Nov 2026.
> Backend yang tersedia di `develop`: Task 1–2 (health, auth, users/profile, gigs/listings + PostGIS).
> Order, barter, dan payments (Task 3–4) masih di `feat/be-payment-simulation-mvp` dan **belum** di-merge ke `develop`, jadi belum dihubungkan.

## 1. Menjalankan backend + database

```bash
# PostGIS lewat Docker (port 5433 agar tidak bentrok dengan Postgres lokal)
docker run -d --name sakuskill_postgis_dev \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=<password_lokal> -e POSTGRES_DB=sakuskill_db \
  -p 127.0.0.1:5433:5432 postgis/postgis:16-3.4-alpine

cd backend
cp .env.example .env      # isi DB_HOST=127.0.0.1, DB_PORT=5433, DB_PASSWORD, JWT_SECRET (acak, ≥32 karakter)
npm install
npm run db:migrate        # 001 + 002
npm run test:api          # uji Task 2
npm start                 # http://localhost:3000/api/v1
```

`DB_HOST=127.0.0.1` (bukan `localhost`): Node 22 me-resolve `localhost` ke `::1`, sedangkan container hanya di-bind ke IPv4.

## 2. Menjalankan aplikasi

| Target | Perintah | Base URL |
| :--- | :--- | :--- |
| Chrome / Windows | `flutter run -d chrome` | `http://localhost:3000/api/v1` (default) |
| Emulator Android | `flutter run` | `http://10.0.2.2:3000/api/v1` (default) |
| HP fisik (USB) | `adb reverse tcp:3000 tcp:3000` lalu `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1` | localhost lewat adb |
| Tanpa backend | `flutter run --dart-define=USE_MOCK_DATA=true` | data demo |

HTTP polos hanya diizinkan untuk build **debug** ke `localhost`/`127.0.0.1`/`10.0.2.2` (`android/app/src/debug/res/xml/network_security_config.xml`). Build release wajib HTTPS (`ApiClient` menolak `http` selain host lokal).

## 3. Yang sudah tersambung

| Fitur FE | Endpoint | Catatan |
| :--- | :--- | :--- |
| Login | `POST /auth/login` | 401 → pesan generik (FR-05); backend hanya menerima email, belum No. WhatsApp |
| Registrasi | `POST /auth/register` | 422 `details[].field` dan 409 email terdaftar tampil di field terkait. No. WhatsApp & domisili belum disimpan (kolomnya belum ada) |
| Logout | `POST /auth/logout` | sesi lokal selalu dihapus walau server tidak terjangkau |
| Sesi | header `Authorization: Bearer` | token di `flutter_secure_storage`; 401 atas token yang dikirim → sesi dihapus |
| Beranda / Explore / Peta | `GET /listings?lat&lng&radius_m` | `latitude/longitude`, `rata_rata_rating`, `deskripsi_imbalan_barter` dipetakan |

## 4. Pengujian

```bash
cd mobile
flutter test --exclude-tags live                     # 108 tes offline
flutter test test/integration/backend_live_test.dart \
  --dart-define=BACKEND_URL=http://127.0.0.1:3000/api/v1   # 9 uji kontrak ke backend asli
```

Uji live membuat akun + gig uji dengan email unik, memeriksa health/PostGIS, register (201/409/422), login (401/200), `GET /users/me`, gig baru muncul di Discovery dan ter-parse, logout mencabut token, dan 401 menghapus sesi.

## 5. Temuan untuk tim

1. **`backend/package-lock.json` tidak sinkron** dengan `package.json` (`bcryptjs` lock 3.0.3 vs `^2.4.3`), jadi `npm ci` gagal. Perlu `npm install` lalu commit lock oleh Anggota 5.
2. **Payments/order/barter belum di `develop`**. Laporan Task 4 (simulasi pembayaran, `pending/success/failed`) ada di `feat/be-payment-simulation-mvp`; dokumen master Rev1 juga masih memuat versi Midtrans/escrow (`feat/be-payment-escrow-gateway`). Perlu dipastikan mana yang di-merge sebelum layar escrow/barter disambungkan.
3. **Status payment baru (`pending/success/failed`, label Menunggu/Berhasil/Gagal)** berbeda dari enum `payment_status_enum` di migrasi 001 yang dipakai FE (T-08). Perlu keputusan PM sebelum FE mengikutinya.
4. **`develop` 6de3e36 mengembalikan `package:flutter/material.dart`** (menggantikan `material_ui`, keputusan T-03). Branch ini mengikuti develop; di Flutter 3.50 hasilnya 66 info `deprecated_member_use` (bukan error). Tim perlu menyepakati satu versi Flutter.
5. `AndroidManifest.xml` utama belum punya izin `INTERNET`, sehingga APK release tidak bisa memanggil backend. Sudah ditambahkan di branch ini.
6. Deep link web `/#/auth/register` menampilkan "Halaman tidak ditemukan" karena Flutter mendorong rute antara `/auth`. Ini minor dan belum diperbaiki.
