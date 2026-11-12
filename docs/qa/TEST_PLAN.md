# SakuSkill — Quality Assurance (QA) Test Plan & Strategy

> **Dokumen Resmi QA & Rencana Pengujian MVP SakuSkill**  
> **Target Rilis:** Sprint 1 — MVP Demo  
> **Status:** Active / In-Progress  
> **PIC QA:** QA Tester & DevOps Engineer  

---

## 1. Pendahuluan & Tujuan
Dokumen ini merinci strategi, ruang lingkup pengujian, kriteria penerimaan (*acceptance criteria*), dan standar keparahan bug (*bug severity*) untuk aplikasi **SakuSkill** (Platform Marketplace Skill & Micro-Services Mahasiswa). 

Tujuan utama pengujian adalah memastikan seluruh skenario kritis MVP (Autentikasi, Katalog Layanan, Transaksi Pembayaran Escrow, dan Sistem Barter Keahlian) berjalan stabil, aman, dan tanpa hambatan sebelum sesi demo rilis.

---

## 2. Ruang Lingkup Pengujian (Scope of Testing)

### A. Fitur Dalam Cakupan (In-Scope MVP):
1. **Autentikasi & Akun:** Registrasi email kampus, login, logout, sesi pengguna, proteksi rute.
2. **Peran Multi-Fungsi (Dual Role):** Pengguna dapat bertindak fleksibel sebagai Pelanggan (*Client*) maupun Penyedia Jasa (*Provider*).
3. **Profil Mahasiswa:** Pengaturan profil, portofolio keahlian, dan saldo dompet/escrow virtual.
4. **Manajemen Layanan (Gigs):** Pembuatan tawaran jasa baru, penentuan harga/kategori, dan edit layanan.
5. **Eksplorasi & Discovery:** Pencarian jasa, penyaringan kategori kampus, dan rincian halaman layanan (*Service Detail*).
6. **Alur Pemesanan & Pembayaran (Order & Escrow Payment Simulation):** Pembuatan pesanan, simulasi pembayaran sukses, dan penanganan pembayaran gagal (*failed state*).
7. **Sistem Barter Keahlian (*Skill Swap*):** Pengajuan proposal tukar jasa, kesepakatan nilai imbang, persetujuan kedua pihak, dan penolakan barter.
8. **Pembatalan & Sengketa (*Cancellation*):** Pembatalan pesanan sebelum dikerjakan dan proteksi dana tertahan di escrow.
9. **Ulasan & Penilaian (*Review & Rating*):** Pengiriman ulasan bintang 1–5 serta komentar testimoni pasca-pesanan selesai.

### B. Di Luar Cakupan (Out-of-Scope Sprint Ini):
- Integrasi payment gateway riil (Midtrans/Xendit live production) — *menggunakan simulator sandbox/mock*.
- Notifikasi push realtime FCM lanjutan.

---

## 3. Matriks Keparahan Bug (Bug Severity Matrix)

| Tingkat Severity | Definisi & Dampak | Wajib Selesai Sebelum Demo? | Contoh Kasus |
| :--- | :--- | :---: | :--- |
| 🛑 **Blocker** | Aplikasi crash total, freeze permanen, kebocoran data, atau alur transaksi terhenti tanpa solusi alternatif. | **YA (Wajib 100%)** | Aplikasi langsung force-close saat membuka halaman checkout order. |
| 🔴 **Critical** | Fitur utama gagal bekerja, perhitungan nominal uang/saldo salah, alur barter/pembayaran tidak menghasilkan status akhir. | **YA (Wajib 100%)** | Tombol "Bayar Sekarang" tidak merespons, order tidak terbentuk di database. |
| 🟠 **Major** | Fitur tidak bekerja optimal sesuai spesifikasi, namun pengguna masih memiliki alur alternatif (*workaround*). | **Diusahakan** | Filter pencarian kategori lambat atau pagination melompati halaman. |
| 🟡 **Minor** | Kesalahan kosmetik antarmuka (UI), kesalahan ketik teks (*typo*), atau margin styling yang kurang presisi. | **Boleh Ditunda** | Teks deskripsi terpotong 1 karakter, warna icon tidak sesuai tema. |

> **Aturan Kelulusan Demo (Quality Gate):**  
> Sistem dinyatakan **SIAP DEMO** jika terdapat **0 Blocker** dan **0 Critical Bug** yang terbuka (*open*).

---

## 4. Akun Uji Coba Standar (Predefined Test Data)

Untuk memfasilitasi pengujian transaksi dua arah (Penyedia vs Pelanggan) dan skenario barter antar-mahasiswa:

| Data Uji | Pengguna 1 (Penyedia Jasa / Akun A) | Pengguna 2 (Pelanggan / Akun B) |
| :--- | :--- | :--- |
| **Nama Lengkap** | Salma Anindya | Arya Pratama |
| **Email UIN SGD** | `salma.designer@uinsgd.ac.id` | `arya.klien@uinsgd.ac.id` |
| **Password** | `SakuSkill123!` | `SakuSkill123!` |
| **Peran Utama** | Penyedia Jasa Desain Poster & UI | Mahasiswa Klien / Pencari Jasa |
| **Saldo Mock** | Rp 250.000 | Rp 500.000 |
| **Keahlian** | UI/UX Design, Figma, Poster Canva | Copywriting, Python Scripting |

---

## 5. Rencana Jadwal Eksekusi Pengujian (QA Schedule)
1. **12–13 Nov 2026:** Finalisasi Test Plan, Test Case Matrix, dan Bug Report Template.
2. **14–15 Nov 2026:** Smoke Testing dan Component Functional Testing (saat FE & BE push modul awal).
3. **16 Nov 2026:** Integration Testing & End-to-End Regression Testing (Alur transaksi pembayaran & barter).
4. **17 Nov 2026:** Sign-off QA & Persiapan Demo Rilis MVP.
