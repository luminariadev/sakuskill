# PANDUAN DEPLOYMENT CLOUD GRATIS (ZERO-COST STACK)
## Deploy Backend + Web Admin SakuSkill (1 Project Tanpa Kartu Kredit) & Rilis APK Mobile
**Target Proyek:** SakuSkill Monorepo (`api/` + `backend/` + `admin/` + `mobile/`)  
**Database:** Neon.tech *(Direkomendasikan)* (Serverless PostgreSQL + PostGIS - 100% Free Tanpa Kartu)  
**Hosting Utama (Tanpa Kartu Kredit):** **Vercel Hobby Plan** (`sin1` Singapore — 1 URL untuk Express API `/api/v1/*`, `/health`, dan React/Vite Web Admin `/admin/`)  
**Hosting Alternatif (PaaS Tradisional):** Render.com (`render.yaml`, beberapa akun memerlukan verifikasi kartu \$1 via Stripe)  
**Distribusi Mobile:** Direct APK Install / GitHub Releases

---

## 1. Arsitektur Deployment Cloud (Vercel + Neon, 1 URL Terpadu)

```mermaid
flowchart LR
    A["HP Pengguna 1\n(Android APK)"] -->|"HTTPS /api/v1/*"| C["Vercel Project (Singapore sin1)\napi/index.js + CDN /admin/"]
    B["HP Pengguna 2\n(Android APK)"] -->|"HTTPS /api/v1/*"| C
    E["Browser Administrator"] -->|"HTTPS /admin/"| C
    C -->|"PostgreSQL SSL Pool"| D["Neon.tech (Singapore)\nDatabase SakuSkill"]
```

Kenapa Vercel + Neon aman untuk backend SakuSkill:
* **100% Stateless REST + JWT + PostgreSQL:** SakuSkill tidak bergantung pada WebSocket atau penyimpanan file lokal; semua data user, foto profil (base64 data URI terkompresi), layanan, pesanan escrow, barter, laporan, dan audit tersimpan permanen di **Neon PostgreSQL**.
* **Web Admin & API dalam 1 Domain:** Aset statis `admin/dist` disajikan lewat CDN `/admin/` sedangkan endpoint `/`, `/health`, dan `/api/v1/*` dijalankan oleh [api/index.js](api/index.js) di region Singapore (`sin1`) tanpa tidur 30–50 detik seperti Render Free Tier.

---

## 2. Tahap 1: Siapkan Database PostgreSQL Gratis di Neon.tech

1. Buka [https://console.neon.tech](https://console.neon.tech) → login dengan akun GitHub `luminariadev`.
2. Di proyek Neon Anda (Region `Singapore / ap-southeast-1`, Postgres 16), klik tombol **Connect**.
3. Salin **Connection String** (berakhiran `?sslmode=require`), contoh:
   ```env
   postgresql://neondb_owner:xxxxxx@ep-xxxx-xxxx-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   ```

---

## 3. Tahap 2: Deploy 1 Project ke Vercel (100% Tanpa Kartu Kredit)

Berkas [vercel.json](vercel.json), [package.json](package.json), [api/index.js](api/index.js), dan [scripts/vercel-build.js](scripts/vercel-build.js) sudah siap pakai.

1. Buka [https://vercel.com](https://vercel.com) → login dengan GitHub `luminariadev` *(Hobby Plan gratis, tanpa kartu kredit)*.
2. Klik **Add New...** → **Project** → **Import** repositori `luminariadev/sakuskill`.
3. Biarkan **Root Directory** tetap di `./` dan **Framework Preset** di `Other` *(Vercel otomatis membaca `vercel.json`)*.
4. Buka bagian **Environment Variables** dan tambahkan:
   * `DATABASE_URL` = *(tempel Connection String dari Neon)*
   * `JWT_SECRET` = *(string acak rahasia minimal 32 karakter)*
   * `NODE_ENV` = `production`
   * `API_PREFIX` = `/api/v1`
   * `JWT_EXPIRES_IN` = `7d`
   * `DEFAULT_CAMPUS_LAT` = `-6.9311`
   * `DEFAULT_CAMPUS_LNG` = `107.7175`
   * `DEFAULT_HYPERLOCAL_RADIUS_METERS` = `3000`
5. Klik **Deploy**.
6. **Penting — Pastikan Production Branch memakai `release/v1.0.0-mvp`:**
   * Buka **Project Settings → Environments → Production** *(atau **Settings → Git → Production Branch**)*.
   * Ubah **Production Branch** dari `main` menjadi **`release/v1.0.0-mvp`**, simpan, lalu **Redeploy** dari tab Deployments *(atau klik **Create Deployment** untuk branch `release/v1.0.0-mvp`)*.
7. Saat build `release/v1.0.0-mvp` selesai:
   * `scripts/vercel-build.js` otomatis membangun `admin/dist` ke `vercel-public/admin` serta menjalankan migrasi database **`001`–`007`** secara idempoten ke Neon (termasuk membuat akun Web Admin bawaan: `admin@sakuskill.ac.id` / `admin1234` pada DB baru).

---

## 4. Tahap 3: Verifikasi Backend & Web Admin Cloud

Setelah status deployment **Ready** (misalnya `https://sakuskill.vercel.app`):

1. Cek Health API:
   ```bash
   curl -L https://<project-anda>.vercel.app/health
   ```
   Respons yang diharapkan:
   ```json
   {"status":"ok","service":"sakuskill-backend","timestamp":"..."}
   ```
2. Cek Web Admin Portal:
   Buka `https://<project-anda>.vercel.app/admin/` dan login dengan `admin@sakuskill.ac.id` (`admin1234`).

---

## 5. Tahap 4: Build APK Android Terhubung Permanen ke Vercel

Setelah URL Vercel aktif, kompilasi APK release dengan menyuntikkan URL Vercel Anda:

```bash
cd "D:\Kuliah\Sosio Informatika\sakuskill-mobile\mobile"
flutter build apk --release --dart-define=API_BASE_URL=https://<project-anda>.vercel.app/api/v1
```

Berkas hasil kompilasi berada di `mobile/build/app/outputs/flutter-apk/app-release.apk` dan dapat langsung dipasang di HP Anda serta HP penguji lain untuk transaksi & sinkronisasi real-time dengan Web Admin.

---

## Opsi Sekunder: Render.com (`render.yaml`)
Jika akun Render Anda terverifikasi, `render.yaml` juga tetap tersedia dengan `rootDir: .` dan single-service Express + static `/admin/`.
