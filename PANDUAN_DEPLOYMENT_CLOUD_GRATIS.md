# PANDUAN DEPLOYMENT CLOUD GRATIS (ZERO-COST STACK)
## Menjalankan Backend SakuSkill di Cloud & Rilis APK Mobile Multi-Device
**Target Proyek:** SakuSkill Monorepo (`backend/` + `mobile/`)  
**Database:** Neon.tech / Supabase (Serverless PostgreSQL - 100% Free)  
**Backend:** Render.com (Web Service Node.js - 100% Free Tier)  
**Distribusi Mobile:** GitHub Releases (Direct APK Download via Internet)  

---

## 1. Arsitektur Deployment Cloud

```mermaid
flowchart LR
    A["HP Pengguna 1\n(Android APK)"] -->|"HTTPS / Internet"| C["Backend Render.com\n(Express.js Web Service)"]
    B["HP Pengguna 2\n(Android APK)"] -->|"HTTPS / Internet"| C
    C -->|"PostgreSQL SSL Connection"| D["Neon.tech / Supabase\n(Cloud Database)"]
    E["Admin Web Panel\n(Next.js)"] -->|"HTTPS / Internet"| C
```

---

## 2. Tahap 1: Setup Database PostgreSQL Gratis (Neon.tech / Supabase)

Pilih salah satu (direkomendasikan **Neon.tech** karena paling cepat dan ramah serverless):

### Opsi A: Menggunakan Neon.tech (Paling Direkomendasikan)
1. Buka [https://neon.tech](https://neon.tech) dan login dengan akun GitHub Anda (`luminariadev`).
2. Klik **"Create Project"**:
   - Project Name: `sakuskill-db`
   - Region: `Asia (Singapore)` *(pilih Singapore agar latensi ke Indonesia < 30ms)*
   - PostgreSQL Version: `16`
3. Salin **Connection String** yang muncul:
   Formatnya:
   ```env
   postgresql://luminariadev:xxxxxx@ep-cool-fog-12345.ap-southeast-1.aws.neon.tech/sakuskill-db?sslmode=require
   ```

### Opsi B: Menggunakan Supabase
1. Buka [https://supabase.com](https://supabase.com) dan buat project baru:
   - Name: `sakuskill`
   - Database Password: *(buat password yang kuat)*
   - Region: `Singapore`
2. Buka menu **Project Settings &rarr; Database &rarr; Connection string &rarr; URI**:
   Salin string koneksi:
   ```env
   postgresql://postgres.xxxxxx:[YOUR-PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres
   ```

---

## 3. Tahap 2: Deploy Backend ke Render.com (100% Gratis)

Kami sudah menyiapkan berkas `render.yaml` (Render Blueprint) dan script `npm run start:prod` di backend, sehingga migrasi database akan dijalankan otomatis saat deployment!

1. Buka [https://render.com](https://render.com) dan login menggunakan akun GitHub Anda (`luminariadev`).
2. Klik tombol **"New +"** di pojok kanan atas &rarr; pilih **"Blueprint"** (atau **"Web Service"**).
3. Sambungkan repositori GitHub Anda: `luminariadev/sakuskill`.
4. Jika menggunakan **Web Service Manual**:
   - **Name**: `sakuskill-backend`
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Region**: `Singapore`
   - **Branch**: `release/v1.0.0-mvp` (atau branch utama Anda)
   - **Build Command**: `npm install`
   - **Start Command**: `npm run start:prod`
   - **Instance Type**: `Free`
5. Pada bagian **Environment Variables**, tambahkan:
   - `DATABASE_URL` = *(isi dengan connection string dari Neon/Supabase di Tahap 1)*
   - `NODE_ENV` = `production`
   - `JWT_SECRET` = `sakuskill_secure_jwt_production_key_32chars`
   - `PORT` = `10000`
   - `API_PREFIX` = `/api/v1`
6. Klik **"Create Web Service"**.
   - Render akan mengunduh dependensi, menjalankan migrasi database (`001` hingga `006_create_order_time_extensions.sql`), dan menyalakan server.
   - Anda akan mendapatkan URL HTTPS gratis, contoh: `https://sakuskill-backend.onrender.com`.

---

## 4. Tahap 3: Uji Coba Health & Endpoint Backend Cloud

Buka browser atau terminal untuk memverifikasi bahwa backend Anda sudah online:
```bash
curl -L https://sakuskill-backend.onrender.com/health
```
Respons yang diharapkan:
```json
{"status":"ok","service":"sakuskill-backend","timestamp":"2026-11-24T..."}
```

---

## 5. Tahap 4: Build APK Android yang Terhubung ke Cloud

Setelah backend aktif di Render (misal: `https://sakuskill-backend.onrender.com`):

1. Masuk ke direktori `mobile`:
   ```bash
   cd "D:\Kuliah\Sosio Informatika\sakuskill-mobile\mobile"
   ```
2. Build Release APK dengan menyuntikkan URL backend Render Anda:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://sakuskill-backend.onrender.com/api/v1
   ```
3. Berkas APK hasil kompilasi akan berada di:
   `mobile/build/app/outputs/flutter-apk/app-release.apk`
   Ukuran APK sekitar 18-25 MB (teroptimasi, tanpa bloatware).

---

## 6. Tahap 5: Rilis APK ke GitHub Releases & Uji di HP Teman

1. Buka repositori Anda di GitHub: `https://github.com/luminariadev/sakuskill/releases`.
2. Klik **"Draft a new release"**:
   - Tag version: `v1.1.0-cloud`
   - Target branch: `release/v1.0.0-mvp`
   - Release title: `SakuSkill v1.1.0 (Live Cloud Demo)`
   - Attach binaries: Unggah berkas `app-release.apk`.
3. Klik **"Publish release"**.
4. **Uji Coba di HP Fisik:**
   - Bagikan tautan release GitHub ke HP Anda dan HP teman-teman Anda.
   - Unduh dan pasang (install) `app-release.apk`.
   - Buka aplikasi menggunakan koneksi data internet (Wi-Fi kampus, Telkomsel/Indosat/XL, dsb).
   - Pengguna 1 login/registrasi dan membuat penawaran jasa.
   - Pengguna 2 di HP lain langsung bisa melihat jasa tersebut di Discovery dan melakukan pemesanan / barter / chat secara *real-time*!
