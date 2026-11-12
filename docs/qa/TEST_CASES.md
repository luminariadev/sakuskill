# SakuSkill — QA Test Cases Matrix

> **Modul Pengujian MVP SakuSkill**  
> **Format Kasus:** Positive (✅), Negative (❌), Boundary/Edge Case (⚠️)  
> **Status:** Siap Dieksekusi saat Modul FE/BE Terintegrasi  

---

## Modul 1: Autentikasi & Akun Pengguna

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-AUTH-001` | ✅ | Registrasi Akun Baru Mahasiswa Sukses | Masukkan Nama, Email Kampus valid, Password kuat, konfirmasi password, klik Daftar. | `nama: "Budi", email: "budi@uinsgd.ac.id", pass: "Saku123!"` | Akun berhasil terdaftar, diarahkan ke verifikasi / dashboard. |
| `TC-AUTH-002` | ❌ | Registrasi dengan Email Non-Kampus | Masukkan email publik umum (bukan domain kampus). | `email: "budi@gmail.com"` | Muncul pesan error validasi: "Wajib menggunakan email institusi kampus (.ac.id)". |
| `TC-AUTH-003` | ❌ | Login dengan Password Salah | Masukkan email terdaftar dan password keliru. | `pass: "Salah123"` | Muncul alert: "Email atau password yang Anda masukkan salah". |
| `TC-AUTH-004` | ⚠️ | Boundary Panjang Password | Masukkan password kurang dari batas minimum (< 8 karakter). | `pass: "12345"` | Muncul peringatan: "Password minimal 8 karakter dengan kombinasi angka & huruf". |

---

## Modul 2: Peran Multi-Fungsi (Dual Role) & Profil

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-PROF-001` | ✅ | Beralih Antara Mode Pelanggan & Penyedia | Buka halaman profil, klik toggle "Mode Penyedia Jasa". | Akun Aktif | Dashboard menampilkan opsi kelola layanan (gigs) dan riwayat order masuk. |
| `TC-PROF-002` | ✅ | Edit Portofolio & Skill Tag | Tambahkan tag skill baru dan simpan profil. | `skills: ["Figma", "Canva"]` | Tag skill tersimpan dan tampil pada kartu profil publik. |
| `TC-PROF-003` | ⚠️ | Boundary Ukuran Upload Foto Avatar | Unggah foto profil melebihi batas (misal > 5 MB). | `avatar: 10MB.png` | Sistem menolak dengan pesan "Ukuran berkas maksimal 2 MB". |

---

## Modul 3: Manajemen Layanan (Create/Edit Gigs)

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-GIGS-001` | ✅ | Tambah Layanan Jasa Baru Berhasil | Buka menu Buat Jasa, isi judul, kategori, deskripsi, harga, klik Terbitkan. | `judul: "Jasa Desain Slide PPT", harga: 35000` | Layanan berhasil dibuat dan langsung muncul pada katalog publik. |
| `TC-GIGS-002` | ❌ | Form Pembuatan Jasa Dikosongkan | Klik Terbitkan tanpa mengisi judul atau harga. | Field kosong | Validasi error muncul pada field wajib (*required fields*). |
| `TC-GIGS-003` | ⚠️ | Boundary Batas Minimum & Maksimum Harga | Masukkan harga di bawah Rp 5.000 atau di atas Rp 10.000.000. | `harga: 500` | Sistem menolak dengan batas batas: "Nominal jasa minimal Rp 5.000". |

---

## Modul 4: Eksplorasi Layanan (Discovery & Detail)

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-DISC-001` | ✅ | Pencarian Jasa dengan Kata Kunci Valid | Ketik kata kunci pada bilah pencarian katalog. | `q: "desain"` | Menampilkan daftar layanan yang relevan dengan kata kunci. |
| `TC-DISC-002` | ❌ | Pencarian Jasa dengan Kata Kunci Tidak Ditemukan | Masukkan karakter acak yang tidak ada di basis data. | `q: "zzzzxyz999"` | Menampilkan ilustrasi *empty state*: "Layanan tidak ditemukan". |
| `TC-DISC-003` | ✅ | Membuka Halaman Rincian Layanan | Klik salah satu kartu jasa pada beranda. | Gig ID Valid | Memuat rincian deskripsi lengkap, profil penyedia, tarif, dan opsi Order/Barter. |

---

## Modul 5: Alur Pemesanan & Simulasi Pembayaran (Order & Escrow)

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-ORDR-001` | ✅ | Pembuatan Pesanan Berbayar Sukses | Buka rincian jasa, klik "Pesan Jasa", pilih metode simulasi, konfirmasi pembayaran. | Akun Arya (Pelanggan) memesan jasa Salma | Pesanan terbentuk dengan status `MENUNGGU_KONFIRMASI_PENYEDIA`, dana tertahan di Escrow. |
| `TC-ORDR-002` | ❌ | Simulasi Pembayaran Gagal | Pilih skenario simulasi pembayaran gagal / saldo mock tidak mencukupi. | Saldo: Rp 0, Order: Rp 50.000 | Pembayaran ditolak, pesanan tidak dilanjutkan, status `PAYMENT_FAILED`. |
| `TC-ORDR-003` | ❌ | Pengguna Memesan Jasanya Sendiri | Akun penyedia membuka jasa miliknya sendiri lalu mencoba klik Pesan. | Akun Salma mencoba memesan jasa Salma | Tombol pemesanan dinonaktifkan (*disabled*) atau muncul peringatan proteksi. |
| `TC-ORDR-004` | ⚠️ | Pencegahan Double-Submit Checkout | Klik tombol "Konfirmasi Pesanan" secara cepat berulang-ulang (*rapid click*). | 5x klik cepat | Sistem hanya memproses 1 transaksi (idempotency key aman). |

---

## Modul 6: Sistem Barter Keahlian (Skill Barter)

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-BARTER-001` | ✅ | Pengajuan Proposal Barter Sukses | Buka rincian jasa Salma, pilih opsi "Ajukan Barter", pilih jasa tandingan milik Arya, klik Kirim. | Jasa Desain dibarter dengan Jasa Copywriting | Proposal barter terkirim dengan status `PENDING_REVIEW_PARTNER`. |
| `TC-BARTER-002` | ✅ | Penyedia Menyetujui Proposal Barter | Salma membuka daftar barter masuk, klik "Setujui Barter". | Proposal ID Valid | Status barter berganti menjadi `BARTER_ACTIVE_IN_PROGRESS` untuk kedua pihak. |
| `TC-BARTER-003` | ❌ | Penyedia Menolak Proposal Barter | Salma membuka proposal barter lalu klik "Tolak Barter" beserta alasan penolakan. | Alasan: "Waktu tidak cocok" | Status barter ditutup menjadi `BARTER_REJECTED`. |

---

## Modul 7: Pembatalan Pesanan & Sengketa (Cancellation)

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-CANCEL-001` | ✅ | Pembatalan oleh Pelanggan Sebelum Dikonfirmasi | Pelanggan membatalkan pesanan sebelum penyedia memulai pengerjaan. | Order status `WAITING` | Pesanan dibatalkan (`CANCELLED`), dana escrow otomatis dikembalikan ke saldo pelanggan. |
| `TC-CANCEL-002` | ❌ | Pembatalan Sepihak Saat Pengerjaan Sedang Berlangsung | Pelanggan mencoba membatalkan saat status sudah `IN_PROGRESS`. | Order status `IN_PROGRESS` | Sistem menolak pembatalan sepihak dan mengarahkan ke menu pengajuan sengketa/mediasi. |

---

## Modul 8: Ulasan & Penilaian (Review & Rating)

| ID Test | Tipe | Skenario Pengujian | Langkah Pengujian | Data Uji | Hasil yang Diharapkan |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `TC-REV-001` | ✅ | Pengiriman Ulasan Setelah Pesanan Selesai | Buka pesanan berstatus `COMPLETED`, pilih bintang 5, tulis komentar testimoni, klik Kirim. | `rating: 5, review: "Hasil desain sangat memuaskan dan cepat!"` | Ulasan berhasil diterbitkan dan rating rata-rata penyedia ter-update. |
| `TC-REV-002` | ❌ | Mengirim Ulasan Pada Pesanan yang Belum Selesai | Mencoba memanggil endpoint / form review pada pesanan aktif atau dibatalkan. | Order status `IN_PROGRESS` | Akses form review ditolak sampai pesanan dikonfirmasi selesai oleh kedua pihak. |
