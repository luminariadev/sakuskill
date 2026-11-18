# Changelog

Semua perubahan penting pada proyek **SakuSkill Monorepo** didokumentasikan dalam berkas ini.
Format ini mengacu pada [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) dan mematuhi [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-mvp] - 2026-11-18

### 🚀 Ditambahkan (Added)
- **Web Admin Panel (React 18 + Vite SPA):**
  - Dashboard eksekutif KPI: metrik pengguna, transaksi aktif escrow, moderasi jasa, dan sengketa terbuka.
  - Modul verifikasi identitas mahasiswa (KTM upload modal) dengan persetujuan (*approve*) dan penolakan (*reject*).
  - Modul moderasi jasa dengan analisis kepatuhan etika akademik dan deteksi otomatis joki tugas ilegal.
  - Modul monitoring rekening bersama simulasi (Escrow Monitoring) dengan aksi pelepasan saldo penampungan.
  - Modul pusat penyelesaian sengketa (Dispute Resolution Center) dengan sidang mediasi admin dan eksekusi vonis bagi hasil (Opsi A 100% Refund, Opsi B 100% Release, Opsi C Split 50:50).
- **Keamanan Siber & DevSecOps Hardening (Standar Industri):**
  - Implementasi rate limiting bertingkat menggunakan `express-rate-limit`:
    - `authRateLimiter`: Membatasi maksimal 12 percobaan per IP per menit pada endpoint `/login` dan `/register` (mitigasi Credential Stuffing & Dictionary Attack).
    - `globalRateLimiter`: Membatasi maksimal 150 request per IP per menit (mitigasi DoS & HTTP Flood).
  - Pembatasan body payload JSON maksimal 2MB (`express.json({ limit: '2mb' })`) untuk mencegah Memory Exhaustion / ReDoS.
  - Proteksi header HTTP dengan `helmet()` (X-Frame-Options, X-Content-Type-Options: nosniff, X-XSS-Protection, masking header `X-Powered-By`).
  - Pemisahan token otorisasi Bearer JWT dengan masa berlaku 7 hari dan mekanisme pencabutan instan (*revoked tokens blacklist* via klaim `jti`).
  - Penegakan integritas data: 100% database query menggunakan *Parameterized Prepared Statements* (`$1, $2, ...`) yang kebal terhadap 5 varian serangan SQL Injection.
  - Perekaman otomatis seluruh mutasi transaksi dan status ke tabel `audit_logs`.
- **Infrastruktur DevOps & Jaringan Hybrid:**
  - Integrasi Cloudflare Edge Tunnel (`cloudflared.exe`) untuk mengekspos REST API port 3000 secara aman melalui HTTPS publik tanpa batasan sesi, tanpa port forwarding, dan tanpa firewall NAT blocking.
  - Skrip reset database instan sekali klik (`npm run db:clean`) untuk mengosongkan 10 tabel transaksi secara kaskade (`CASCADE`), membersihkan pengguna dummy, dan mempertahankan akun Administrator sistem (`admin@sakuskill.ac.id`) serta 7 master kategori keahlian kampus.
  - Penyusunan berkas dokumentasi formal berformat Microsoft Word (`.docx`):
    - `PANDUAN_DEVOPS_DAN_ARSITEKTUR_SISTEM_SAKUSKILL.docx`
    - `LAPORAN_AUDIT_KEAMANAN_DAN_DEVSECOPS_SAKUSKILL.docx`
- **Penerbitan Rilis Produksi (GitHub Releases):**
  - Penerbitan rilis resmi `v1.0.0-mvp` pada GitHub Releases repositori `luminariadev/sakuskill`.
  - Kompilasi dan pengunggahan biner Android rilis ARM64 (`sakuskill-app-release.apk`, 18.29 MB).

### 🔄 Diubah & Disesuaikan (Changed)
- **Penyesuaian Antarmuka Registrasi (Sesuai Desain Figma Terbaru):**
  - Menghapus pemilihan peran kaku (*Penyedia vs Pemesan*) pada halaman registrasi. Mahasiswa otomatis memiliki peran ganda yang fleksibel (dapat mencari jasa sekaligus menawarkan keahlian).
  - Mengosongkan form login dari kredensial hardcode bawaan.
- **Kerapian Antarmuka Produksi Mobile:**
  - Menghilangkan icon tombol pengaturan jaringan pada halaman Login, Registrasi, dan Profil agar tampilan antarmuka 100% bersih seperti aplikasi komersial resmi.
  - Menambahkan *Hidden Dev Gesture* darurat: Menekan tahan (*long-press*) selama 2 detik teks versi footer di halaman Profil membuka dialog pengaturan URL API server.
- **Optimasi Kinerja & Render Mobile:**
  - Mengoptimasi kurva animasi transisi halaman untuk mendukung layar berkecepatan 90-120Hz.
  - Mengaktifkan perampingan aset ikon (*icon tree-shaking*), mereduksi ukuran font Material Icons sebesar 99.7%.

### 🔒 Keamanan (Security)
- Menyelesaikan audit keamanan menyeluruh berstandar OWASP Top 10: 2021 dan ASVS v4.0 dengan skor kelayakan **94/100 (Grade A+)**.
- Menyiapkan spesifikasi pipeline CI/CD pengujian penetrasi otonom berbasis AI menggunakan framework **Strix** (`usestrix/strix`).

---

## [1.0.0] - 2026-10-26
- Inisialisasi awal arsitektur SakuSkill Mobile Clean Architecture (Flutter & platform macOS runner).
