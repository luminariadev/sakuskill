# PANDUAN DEPLOYMENT CLOUD GRATIS (ZERO-COST STACK)
## Menjalankan Backend + Web Admin SakuSkill (1 Service) & Rilis APK Mobile Multi-Device
**Target Proyek:** SakuSkill Monorepo (`backend/` + `admin/` + `mobile/`)  
**Database:** Neon.tech *(Direkomendasikan)* / Supabase (Serverless PostgreSQL + PostGIS - 100% Free)  
**Hosting 1 Service:** Render.com (Web Service Node.js untuk Backend `/api/v1/*` + React/Vite Web Admin `/admin/` - 100% Free Tier)  
**Distribusi Mobile:** GitHub Releases / Direct APK Install

---

## 1. Arsitektur Deployment Cloud (1 Service Terpadu)

```mermaid
flowchart LR
    A["HP Pengguna 1\n(Android APK)"] -->|"HTTPS /api/v1/*"| C["Render Web Service\n(Express.js + Static /admin/)"]
    B["HP Pengguna 2\n(Android APK)"] -->|"HTTPS /api/v1/*"| C
    E["Browser Administrator"] -->|"HTTPS /admin/"| C
    C -->|"PostgreSQL SSL Connection"| D["Neon.tech / Supabase\n(Cloud Database)"]
```

---

## 2. Tahap 1: Setup Database PostgreSQL Gratis (Neon.tech / Supabase)

Pilih salah satu (paling direkomendasikan **Neon.tech** karena tidak ada auto-pause 7 hari dan kompatibel langsung dengan IPv4 Render + PostGIS di schema `public`):

### Opsi A: Menggunakan Neon.tech (Paling Direkomendasikan)
1. Buka [https://neon.tech](https://neon.tech) dan login dengan akun GitHub Anda (`luminariadev`).
2. Klik **"Create Project"**:
   - Project Name: `sakuskill-db`
   - Region: `Asia Pacific (Singapore / ap-southeast-1)` *(satu region dengan Render Singapore)*
   - PostgreSQL Version: `16`
3. Salin **Connection String** (Pooled / Direct dengan `?sslmode=require`):
   ```env
   postgresql://neondb_owner:xxxxxx@ep-xxxx-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   ```

### Opsi B: Menggunakan Supabase
> [!NOTE]
> Free tier Supabase akan mem-pause database otomatis setelah 7 hari tidak ada aktivitas (harus di-unpause manual dari dashboard). Selain itu, **Direct Connection** Supabase Free Tier hanya mendukung IPv6, sehingga di Render Free Tier (IPv4) Anda **wajib memakai URI Session Pooler port `:5432`** agar koneksi dan DDL migrasi berjalan lancar.

1. Buka [https://supabase.com](https://supabase.com) dan buat project baru:
   - Name: `sakuskill`
   - Database Password: *(buat password yang kuat)*
   - Region: `Southeast Asia (Singapore)`
2. Buka menu **Connect &rarr; Connection String &rarr; Method: Session pooler** (port `5432`, host `*.pooler.supabase.com`):
   ```env
   postgresql://postgres.xxxxxx:[YOUR-PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres
   ```

---

## 3. Tahap 2: Deploy 1 Service (Backend + Web Admin) ke Render.com

File Blueprint [render.yaml](render.yaml) di root repositori sudah dikonfigurasi untuk membangun **Web Admin (`admin/dist`)** dan menjalankan **Backend (`backend/`)** dalam **1 Web Service** dengan `rootDir: .`:

* **Build Command:**
  ```bash
  npm --prefix admin ci --include=dev && npm --prefix admin run build && npm --prefix backend ci --omit=dev
  ```
  *(Flag `--include=dev` wajib pada `admin` karena Render menyetel `NODE_ENV=production` saat build, sehingga `vite`, `tailwindcss`, dan `@vitejs/plugin-react` tetap terpasang untuk kompilasi aset.)*
* **Start Command:**
  ```bash
  npm --prefix backend run start:prod
  ```
* **Node Runtime:** `NODE_VERSION=22.14.0`

### Langkah Deploy via Render Blueprint (Tercepat):
1. Buka [https://dashboard.render.com](https://dashboard.render.com) dan login dengan akun GitHub (`luminariadev`).
2. Klik **"New +"** &rarr; pilih **"Blueprint"**.
3. Hubungkan repositori `luminariadev/sakuskill` dan pilih branch `release/v1.0.0-mvp`.
4. Render akan otomatis membaca `render.yaml` (`sakuskill-backend`, Region `Singapore`, Plan `Free`).
5. Saat diminta mengisi environment variable **`DATABASE_URL`**, tempelkan Connection String dari Neon (atau Supabase Session Pooler `:5432`).
6. Klik **"Apply"** / **"Deploy"**.
   - Render akan membangun `admin/dist`, memasang dependensi produksi `backend`, menjalankan migrasi **`001` hingga `007`** secara idempoten melalui tabel `schema_migrations`, lalu menyalakan server.
   - Pada database baru, migrasi `007` otomatis membuat akun Web Admin bawaan:
     - **Email:** `admin@sakuskill.ac.id`
     - **Kata Sandi:** `admin1234` *(segera ubah setelah login pertama)*

---

## 4. Tahap 3: Verifikasi Backend & Web Admin Cloud

Setelah deploy Render berstatus **Live**, buka URL publik service Anda (misalnya `https://sakuskill-backend.onrender.com`):

1. Cek Health API:
   ```bash
   curl -L https://sakuskill-backend.onrender.com/health
   ```
   Respons yang diharapkan:
   ```json
   {"status":"ok","service":"sakuskill-backend","timestamp":"..."}
   ```
2. Cek Web Admin Portal:
   Buka browser ke `https://sakuskill-backend.onrender.com/admin/` dan login dengan `admin@sakuskill.ac.id`.

---

## 5. Tahap 4: Build APK Android yang Terhubung Permanen ke Cloud

Default `AppConfig.apiBaseUrl` sudah mengarah ke `https://sakuskill-backend.onrender.com/api/v1` dengan timeout `45` detik untuk mengakomodasi cold-start Render Free Tier. Jika URL Render Anda berbeda, suntikkan saat build:

1. Masuk ke direktori `mobile`:
   ```bash
   cd "D:\Kuliah\Sosio Informatika\sakuskill-mobile\mobile"
   ```
2. Build Release APK:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://<nama-service-anda>.onrender.com/api/v1
   ```
3. Berkas APK hasil kompilasi berada di:
   `mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 6. Tahap 5: Rilis APK & Uji Real-Time Multi-Device

1. Buka `https://github.com/luminariadev/sakuskill/releases` &rarr; **"Draft a new release"**, unggah `app-release.apk`, lalu terbitkan.
2. Pasang APK tersebut di 2 HP atau lebih dengan koneksi internet masing-masing.
3. Aktivitas registrasi, upload foto profil, penawaran jasa, pesanan escrow, maupun barter dari HP langsung tersimpan ke PostgreSQL cloud dan muncul di Web Admin (`/admin/`) dalam <= 15 detik (atau instan dengan tombol **Segarkan**).
