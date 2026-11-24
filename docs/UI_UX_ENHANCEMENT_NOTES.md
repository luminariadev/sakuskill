# Catatan Pembaruan Integrasi Remote & Peningkatan UI/UX Mobile

Dokumen ini merangkum audit sinkronisasi repository remote GitHub, integrasi aset fondasi yang sebelumnya berada di branch `feat/fe-be-integration`, serta penyempurnaan sistem desain aplikasi mobile **SakuSkill** pada branch `release-v1.0.0-mvp`.

---

## 1. Audit Sinkronisasi Remote vs Lokal (`sakuskill-mobile`)

| Branch Remote | Status di Lokal (`release-v1.0.0-mvp`) | Tindak Lanjut |
| :--- | :--- | :--- |
| `origin/develop` | Sudah tergabung penuh (`100%`) | Terverifikasi |
| `origin/release/v1.0.0-mvp` | Basis branch rilis lokal (+15 commit tambahan) | Siap push & deploy |
| `origin/feat/be-auth-gigs-discovery` | Sudah tergabung penuh di `backend/` | Terverifikasi |
| `origin/feat/be-order-barter-lifecycle` | Sudah tergabung penuh di `backend/` | Terverifikasi |
| `origin/feat/be-payment-escrow-gateway` | Sudah tergabung penuh di `backend/` | Terverifikasi |
| `origin/feat/be-payment-simulation-mvp` | Sudah tergabung penuh di `backend/` | Terverifikasi |
| `origin/feat/fe-core-foundation` | Sudah tergabung penuh di `mobile/` | Terverifikasi |
| `origin/feat/fe-discovery` | Sudah tergabung penuh di `mobile/` | Terverifikasi |
| `origin/feat/fe-be-integration` | Branch fondasi lama (tanpa migrasi `003`–`006` & fitur escrow/barter penuh) | **Aset terpilih diambil bersih:** font **Plus Jakarta Sans** (`T-04`), modul teks `EscrowSimCopy`, `network_security_config.xml`, serta test unit font & copy |

---

## 2. Peningkatan Sistem Desain & Hirarki Visual

1. **Tipografi Global (`Plus Jakarta Sans` + Tabular Numerals):**
   - Mengaktifkan font `PlusJakartaSans` (bobot 400, 500, 600, 700, 800) secara global pada `AppTheme.light` (`mobile/pubspec.yaml` & `app_typography.dart`).
   - Pengetatan *letter-spacing* pada judul besar (`-0.5` s.d. `-1.0`) untuk tampilan editorial yang tajam.
   - Menggunakan OpenType `FontFeature.tabularFigures()` pada nominal harga, saldo dompet, stempel waktu chat, serta timer hitung mundur agar angka tidak bergeser saat berdetak.

2. **Palet Warna Tinted Neutral & Kedalaman Kartu:**
   - Mengganti latar abu-abu dingin (`#F8FAFC`) dan gelap polos (`#0F172A`) dengan mineral alabaster bernuansa Emerald (`#F5F7F6`) serta obsidian hutan (`#0B1512` → `#0F2D24`) agar seluruh permukaan selaras dengan warna brand Emerald (`#059669`).
   - Menambahkan sistem elevasi *dual-layer soft shadows* (`AppShadows.card`, `AppShadows.elevated`, `AppShadows.navBar`) pada `SakuCard`, kartu pratinjau peta, dan bar navigasi bawah.

3. **Penyempurnaan Layar Utama & Komponen Transaksi:**
   - **Welcome Screen (`welcome_page.dart`):** Tiga blok fitur disatukan ke dalam satu kartu bernuansa bersih dengan ikon berbingkai lembut.
   - **Beranda (`home_sections.dart` & `market_card.dart`):** Saldo header dikemas menjadi *wallet pill* Emerald, banner Escrow menggunakan gradien obsidian-emerald dengan lencana terproteksi, dan kartu katalog tanpa foto menampilkan ilustrasi gradien + lencana kategori serta chip barter ringkas.
   - **Peta Kampus (`campus_map_page.dart` & `campus_map_widgets.dart`):** Ukuran pin diperkecil (`112×28`) dengan *border halo* putih agar lebih terbaca saat pin berdekatan, serta pin terpilih selalu dirender di lapisan paling atas.
   - **Detail Layanan (`service_detail_page.dart`):** Galeri beradius penuh (`14px`) dengan gradien arsitektural, tombol meta berbentuk *pill*, serta kartu profil penyedia dengan lencana terverifikasi.
   - **Chat & Kotak Masuk (`inbox_page.dart` & `saku_transaction.dart`):** Waktu pesan ditempatkan rapi di kanan atas baris obrolan, konteks order berbentuk lencana ringkas, gelembung chat asimetris, serta *composer* berbentuk *pill* dengan tombol kirim melingkar.
   - **Aktivitas & Dompet (`activity_page.dart`):** Kartu saldo bergaya fintech dengan dua kartu metrik ringkas (`Dana Ditahan Escrow` & `Transaksi Berjalan`), serta indikator progres ganda untuk kontrak Smart Barter aktif.
   - **Navigasi Bawah (`main_shell.dart`):** Penambahan indikator garis aktif di atas tab terpilih dan aksen elevasi halus pada tombol cepat `+`.

---

## 3. Verifikasi

- Seluruh pengujian unit dan widget (`flutter test`) dijalankan setelah perubahan tema dan tata letak.
- Pengujian visual langsung dilakukan pada emulator Android (`Pixel 4a` / `emulator-5554`) mencakup alur Welcome, Login, Beranda, Peta Kampus, Detail Layanan, Chat Escrow, Kotak Masuk, Aktivitas Dompet, serta Smart Barter Workroom.
