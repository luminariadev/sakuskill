# 🚀 SakuSkill v1.0.0-MVP — Platform Marketplace Jasa Mikro & Escrow Mahasiswa

Versi rilis MVP resmi pertama yang telah mengintegrasikan seluruh ekosistem: **Mobile App (Flutter)**, **Backend API (Node.js + PostgreSQL PostGIS)**, dan **Web Admin Panel (React)** secara end-to-end.

---

### 📱 Unduhan Aplikasi Android (Build Rilis)
* **Nama Berkas:** `sakuskill-app-release.apk`
* **Arsitektur:** Android ARM64
* **Ukuran:** 18.3 MB (Dioptimasi dengan asset tree-shaking & compiler release)
* **Konektivitas:** Siap pakai lintas jaringan (Cloudflare Tunnel HTTPS: `https://self-consult-allowed-marijuana.trycloudflare.com/api/v1`)

---

### ✨ Fitur Utama Versi MVP
1. **Autentikasi & Registrasi Fleksibel:**
   - Form bersih tanpa pemilihan peran kaku (mahasiswa otomatis berposisi ganda sebagai pencari & penyedia jasa sesuai desain Figma terbaru).
   - Validasi email mahasiswa, hashing Bcrypt (Work Factor 10), dan proteksi brute force rate limiting.
2. **Discovery & Smart Barter (Hyperlocal):**
   - Pencarian jasa berbasis jarak radius kampus UPI Cibiru (PostGIS).
   - Filter **Smart Barter** untuk pertukaran keahlian non-tunai antar-mahasiswa.
3. **Lifecycle Pesanan & Simulasi Escrow Transaksi (Task 3 & 4):**
   - Alur pemesanan: Pengajuan proposal -> Persetujuan terms -> Penahanan dana di escrow (*holding*) -> Pengerjaan -> Konfirmasi selesai & pencairan dana.
   - Perekaman jejak audit ke tabel `audit_logs` untuk transparansi penuh.
4. **Web Admin Moderasi & Mediasi:**
   - Verifikasi KTM mahasiswa baru.
   - Moderasi jasa dengan deteksi otomatis anti-joki tugas akademik ilegal.
   - Monitoring penahanan saldo escrow dan pusat sengketa (dispute center).
5. **Kesiapan Demonstrasi / DevOps:**
   - Reset database instan: `npm run db:clean`.
   - Hidden gesture konfigurasi API: Tekan tahan teks versi di halaman Profil mobile selama 2 detik.
   - Keamanan enterprise: Express rate limiting (auth & global), helmet, dan 100% parameterized SQL.
