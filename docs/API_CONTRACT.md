# SakuSkill Backend API Contract (v1.3 ? Task 1, 2, 3 & 4)

Dokumen ini adalah acuan integrasi resmi bagi tim **Mobile Flutter** untuk mengakses seluruh modul Backend SakuSkill: **Auth, User Profile, Gigs CRUD, Hyperlocal Discovery (PostGIS), Order Lifecycle, Barter Lifecycle, serta Payment Gateway Eksternal & Rekening Bersama (Escrow)**.

---

## 1. Konfigurasi Base URL & Header Autentikasi

| Lingkungan Klien | Base URL | Keterangan |
| :--- | :--- | :--- |
| **Komputer Lokal / Postman / Web** | `http://localhost:3000/api/v1` | Gunakan saat menguji di PC yang sama dengan server |
| **Android Emulator (AVD)** | `http://10.0.2.2:3000/api/v1` | Alias loopback bawaan Android Emulator ke localhost PC |
| **Perangkat Fisik (HP via Wi-Fi)** | `http://<IP_LAN_LAPTOP>:3000/api/v1` | Pastikan HP dan laptop berada di jaringan Wi-Fi yang sama |

**Header Wajib untuk Endpoint Terproteksi:**
```http
Content-Type: application/json
Authorization: Bearer <jwt_token>
```

---

## 2. Format Standar Response JSON & Kode Error

### A. Response Sukses (`200 OK` / `201 Created`)
```json
{
  "success": true,
  "message": "Pesan deskriptif hasil operasi.",
  "data": {},
  "meta": {}
}
```

### B. Response Error Konsisten (`400`, `401`, `403`, `404`, `409`, `422`)
```json
{
  "success": false,
  "message": "Ringkasan penyebab kegagalan.",
  "error": {
    "code": "KODE_ERROR_STANDAR",
    "details": []
  }
}
```

| HTTP Status | Kode Error (`error.code`) | Keterangan untuk Penanganan di Flutter |
| :--- | :--- | :--- |
| `400` | `INVALID_STATE_TRANSITION` | Transisi status Order/Barter melanggar urutan state machine |
| `400` | `ORDER_NOT_COMPLETED` / `BARTER_NOT_COMPLETED` | Mencoba mengirim review sebelum transaksi berstatus `completed` |
| `400` | `INVALID_ORDER_STATE_FOR_PAYMENT` | Mencoba checkout pembayaran sebelum order disetujui penyedia (`accepted`) |
| `400` | `ESCROW_NOT_FUNDED` | Penyedia mencoba memulai order (`in_progress`) saat tagihan belum masuk Escrow (`held`) |
| `400` | `ORDER_NOT_READY_FOR_RELEASE` | Mencoba melepas dana Escrow sebelum pekerjaan diajukan selesai (`completion_requested`) |
| `400` | `INVALID_ESCROW_TRANSITION` | Mencoba release/refund dana yang tidak berstatus `held` atau order sudah selesai |
| `401` | `UNAUTHORIZED` / `TOKEN_REVOKED` | Token JWT tidak ada, kedaluwarsa, atau sudah di-logout |
| `401` | `INVALID_WEBHOOK_SIGNATURE` | Signature SHA-512 pada notifikasi webhook payment gateway tidak cocok |
| `403` | `FORBIDDEN_NOT_OWNER` | Mencoba mengubah/menghapus gig milik pengguna lain |
| `403` | `FORBIDDEN_NOT_PARTICIPANT` | Pengguna di luar transaksi mencoba mengakses/mengubah Order, Barter, atau Escrow |
| `403` | `FORBIDDEN_ROLE_ACTION` | Aksi dilakukan oleh peran yang salah (misal Penyedia menekan tombol Release Escrow) |
| `404` | `GIG_NOT_FOUND` / `ORDER_NOT_FOUND` / `BARTER_NOT_FOUND` / `PAYMENT_NOT_FOUND` | Data transaksi dengan UUID tersebut tidak ditemukan |
| `409` | `EMAIL_ALREADY_EXISTS` / `REVIEW_ALREADY_EXISTS` / `PAYMENT_ALREADY_SETTLED` | Duplikasi email, ulasan, atau order sudah pernah dibayar lunas |
| `422` | `VALIDATION_ERROR` | Input body/query tidak lolos validasi Zod (lihat array `error.details`) |

---

## 3. Ringkasan Endpoint Auth, Profile, Gigs CRUD & Discovery (Task 1 & 2)

| Modul | Method & Path | Akses | Deskripsi Singkat |
| :--- | :--- | :--- | :--- |
| **Health** | `GET /health` | Publik | Cek status server, database PostgreSQL, dan ekstensi PostGIS |
| **Auth** | `POST /auth/register` | Publik | Registrasi akun (`nama`, `email`, `kata_sandi`, `deskripsi_profil`) & terima JWT |
| **Auth** | `POST /auth/login` | Publik | Login (`email`, `kata_sandi`) & terima JWT |
| **Auth** | `POST /auth/logout` | Bearer | Mencabut sesi token aktif (`revoked_tokens`) |
| **Profile** | `GET /users/me` | Bearer | Mengambil profil sendiri, daftar keahlian, dan `capabilities` multi-peran |
| **Profile** | `PUT /users/me` | Bearer | Update `nama`, `deskripsi_profil`, dan array `skill_ids` (contoh: `[1, 3]`) |
| **Profile** | `GET /users/:id` | Publik | Profil publik penyedia jasa, portofolio, dan ringkasan reputasi |
| **Master** | `GET /gigs/categories` | Publik | Daftar seluruh kategori dan `skill_id` resmi |
| **Discovery** | `GET /gigs` | Publik | Pencarian & filter (`q`, `kategori`, `skill_id`, `tipe_penawaran`, `min_harga`, `max_harga`, `lat`, `lng`, `radius_m`, `use_radius`, `sort_by`) |
| **Gigs** | `GET /gigs/:id` | Publik | Detail satu gig lengkap dengan jarak km, portofolio, dan ulasan terbaru |
| **Gigs** | `POST /gigs` | Bearer | Buat gig baru (`judul`, `deskripsi`, `skill_id`, `harga`, `latitude`, `longitude`, `tipe_penawaran`, `deskripsi_imbalan_barter`, `status`) |
| **Gigs** | `PUT /gigs/:id` | Pemilik | Perbarui data gig milik sendiri (pengguna lain ditolak `403 FORBIDDEN_NOT_OWNER`) |
| **Gigs** | `PATCH /gigs/:id/status` | Pemilik | Ubah status publikasi gig (`Aktif` / `Nonaktif`) |
| **Gigs** | `DELETE /gigs/:id` | Pemilik | Hapus gig yang tidak memiliki transaksi aktif |

---

## 4. Pemetaan Enum Status Order, Barter, Pembayaran & Escrow (Task 3 & 4)

### A. Status Order & Barter (`status_kode` vs Label UI)
| `status_kode` (State Machine) | Label UI (`status_pesanan` / `status`) | Fase Transaksi | Keterangan Status |
| :--- | :--- | :--- | :--- |
| `requested` | `Diajukan` | Awal | Order atau penawaran barter baru dibuat, menunggu respons penyedia/penerima |
| `negotiating` | `Dalam Negosiasi` | Aktif | Sedang dalam pengajuan revisi scope, harga, atau tenggat waktu |
| `accepted` | `Disepakati` | Aktif | Disetujui penyedia (Order) atau disetujui kedua belah pihak (Barter) |
| `in_progress` | `Dikerjakan` | Aktif | Pekerjaan sedang berlangsung |
| `completion_requested` | `Menunggu Konfirmasi` | Aktif | Penyedia mengajukan klaim selesai (Order) atau baru 1 pihak konfirmasi selesai (Barter) |
| `completed` | `Selesai` | Terminal | Pelanggan mengonfirmasi selesai (Order) atau kedua pihak telah konfirmasi selesai (Barter) |
| `rejected` | `Ditolak` | Terminal | Penawaran ditolak oleh penyedia/penerima sebelum disepakati |
| `cancelled` | `Dibatalkan` | Terminal | Transaksi dibatalkan sebelum pengerjaan dimulai (`in_progress`) |

### B. Status Pembayaran (`status_pembayaran_kode`) & Rekening Bersama (`status_escrow_kode`)
| Jenis Status | Kode State Machine | Label UI Bahasa Indonesia | Keterangan |
| :--- | :--- | :--- | :--- |
| **Pembayaran** | `pending` | `Menunggu` | Tagihan sudah terbit di Payment Gateway, menunggu pelunasan pelanggan |
| **Pembayaran** | `settlement` | `Berhasil` | Pembayaran lunas terverifikasi oleh Payment Gateway |
| **Pembayaran** | `failed` | `Gagal` | Pembayaran ditolak atau dibatalkan di Payment Gateway |
| **Pembayaran** | `expired` | `Kedaluwarsa` | Melewati batas waktu pembayaran (24 jam) |
| **Pembayaran** | `refunded` | `Dikembalikan` | Dana pembayaran telah dikembalikan ke pelanggan |
| **Escrow** | `none` | `Belum Aktif` | Dana belum masuk ke Rekening Bersama |
| **Escrow** | `held` | `Ditahan` | Dana aman ditahan di Rekening Bersama SakuSkill selama pengerjaan |
| **Escrow** | `released` | `Dilepas` | Dana telah dicairkan ke saldo Penyedia Jasa setelah order `completed` |
| **Escrow** | `refunded` | `Dikembalikan` | Dana telah dikembalikan ke Pelanggan karena order dibatalkan |

---

## 5. Spesifikasi Endpoint Order Lifecycle (`/api/v1/orders`)

| Method & Path | Aktor yang Diizinkan | Transisi Status | Keterangan & Integrasi Escrow |
| :--- | :--- | :--- | :--- |
| `POST /orders` | Pelanggan | `-> requested` | Membuat order dari gig dengan snapshot harga & ketentuan otomatis |
| `GET /orders` | Partisipan | - | Daftar order milik pengguna (`?role=pelanggan\|penyedia&status=...`) |
| `GET /orders/:id` | Partisipan | - | Detail order beserta `snapshot_gig`, `kesepakatan`, `proposals`, `reviews`, dan `payment_escrow` |
| `POST /orders/:id/proposals` | Pelanggan / Penyedia | `-> negotiating` | Mengajukan penyesuaian scope, harga tawaran, dan usulan deadline |
| `POST /orders/:id/accept` | Penyedia Jasa | `-> accepted` | Menyetujui order dan mengunci kesepakatan scope, harga final, serta deadline |
| `POST /orders/:id/reject` | Penyedia Jasa | `-> rejected` | Menolak order yang berstatus `requested` atau `negotiating` |
| `POST /orders/:id/start` | Penyedia Jasa | `accepted -> in_progress` | Memulai pengerjaan (wajib `status_escrow_kode = held` jika sudah ada tagihan) |
| `POST /orders/:id/request-completion` | Penyedia Jasa | `in_progress -> completion_requested` | Penyedia mengajukan klaim bahwa pekerjaan telah selesai |
| `POST /orders/:id/complete` | Pelanggan | `completion_requested -> completed` | Pelanggan mengonfirmasi selesai & **otomatis mencairkan dana Escrow (`held -> released`)** |
| `POST /orders/:id/cancel` | Pelanggan | `-> cancelled` | Membatalkan order sebelum `in_progress` & **otomatis refund Escrow (`held -> refunded`)** |
| `PATCH /orders/:id/status` | Sesuai Aturan | Sesuai body `status` | Endpoint generik pengubah status (`{"status": "accepted"}` dll.) |
| `POST /orders/:id/reviews` | Pelanggan | Wajib `completed` | Mengirim rating (1-5) & komentar ulasan **hanya setelah order selesai** |

---

## 6. Spesifikasi Endpoint Barter Lifecycle (`/api/v1/barter`)

| Method & Path | Aktor yang Diizinkan | Transisi Status | Keterangan |
| :--- | :--- | :--- | :--- |
| `POST /barter` | Pengaju Barter | `-> requested` | Membuat barter offer merujuk 2 pengguna, deskripsi kedua pekerjaan, & tenggat |
| `GET /barter` | Partisipan | - | Daftar transaksi barter yang melibatkan pengguna |
| `GET /barter/:id` | Partisipan | - | Detail barter beserta objek `persetujuan_kedua_pihak` & `konfirmasi_penyelesaian` |
| `PUT /barter/:id/terms` | Pengaju / Penerima | `-> negotiating` | Memperbarui deskripsi pekerjaan atau tenggat (me-reset persetujuan lawan) |
| `POST /barter/:id/accept` | Penerima / Lawan | `-> accepted` | Menyetujui ketentuan barter sehingga kedua pihak berstatus setuju |
| `POST /barter/:id/reject` | Penerima Barter | `-> rejected` | Menolak pengajuan barter saat masih `requested` atau `negotiating` |
| `POST /barter/:id/start` | Pengaju / Penerima | `accepted -> in_progress` | Memulai pengerjaan barter (ditolak `400` jika belum disetujui kedua pihak) |
| `POST /barter/:id/confirm-completion` | Pengaju & Penerima | `-> completion_requested` lalu `-> completed` | Mencatat konfirmasi penyelesaian masing-masing pihak; selesai jika keduanya konfirmasi |
| `POST /barter/:id/cancel` | Pengaju / Penerima | `-> cancelled` | Membatalkan kesepakatan barter sebelum status `in_progress` |
| `POST /barter/:id/reviews` | Pengaju / Penerima | Wajib `completed` | Memberikan ulasan silang setelah barter resmi selesai (`completed`) |

---

## 7. Spesifikasi Endpoint Payment Gateway Eksternal & Escrow (`/api/v1/payments` & `/api/v1/escrow`)

Seluruh endpoint di bawah ini dapat diakses melalui prefix **`/api/v1/payments`** maupun alias **`/api/v1/escrow`**.

### A. Diagram Alur Pembayaran & Rekening Bersama (Escrow)
```text
1. Penyedia menyetujui Order (status_kode: "accepted")
2. Pelanggan memanggil POST /payments/checkout
   ??> Backend memanggil API Eksternal (Midtrans Snap + Open ExchangeRate API + GoQR QRIS API)
   ??> Menghasilkan snap_token, payment_url, qr_code_url, va_number (status: pending, escrow: none)
3. Pelanggan membayar tagihan (POST /payments/webhook atau POST /payments/:orderId/simulate-pay)
   ??> Verifikasi tanda tangan kriptografi SHA-512
   ??> Status Pembayaran: "settlement" (Berhasil) | Status Escrow: "held" (Ditahan di Rekening Bersama)
4. Penyedia mengerjakan Order (in_progress -> completion_requested)
5. Pencairan atau Pengembalian Dana Escrow:
   ??> Jika Order Selesai (POST /orders/:id/complete atau POST /payments/:orderId/release)
   ?     ??> Status Escrow: "released" (Dilepas ke Penyedia Jasa)
   ??> Jika Order Dibatalkan (POST /orders/:id/cancel atau POST /payments/:orderId/refund)
         ??> Status Pembayaran: "refunded" | Status Escrow: "refunded" (Dikembalikan ke Pelanggan)
```

### B. Daftar Endpoint Payment Gateway & Escrow

| Method & Path | Aktor | Keterangan |
| :--- | :--- | :--- |
| `POST /payments/checkout` | Pelanggan | Membuat tagihan ke Payment Gateway Eksternal (`QRIS`, `GOPAY`, `SHOPEEPAY`, `BCA_VA`, `BNI_VA`, `BRI_VA`, `MANDIRI_BILL`) untuk order yang sudah `accepted` |
| `POST /payments/webhook` | Payment Gateway | Endpoint publik penerima HTTP Notification Midtrans dengan validasi signature `SHA-512` |
| `POST /payments/:orderId/simulate-pay` | Partisipan | Mensimulasikan pelunasan instan ber-signature SHA-512 valid di lingkungan development/testing sehingga dana langsung masuk Escrow (`held`) |
| `POST /payments/:orderId/release` | Pelanggan / Admin | Mencairkan dana Escrow (`held -> released`) ke Penyedia Jasa saat pekerjaan telah `completion_requested` atau `completed` |
| `POST /payments/:orderId/refund` | Pelanggan / Penyedia / Admin | Mengembalikan dana Escrow (`held -> refunded`) ke Pelanggan apabila order dibatalkan sebelum selesai |
| `GET /payments/:orderId` | Partisipan | Mengambil detail tagihan, URL gambar QRIS eksternal, nomor VA, dan status Escrow untuk 1 order |
| `GET /payments` atau `GET /payments/summary` | Pengguna Login | Mengambil daftar riwayat transaksi pembayaran beserta `meta` rekapitulasi saldo Escrow pengguna |

### C. Contoh Request & Response Payment Gateway & Escrow

#### 1. Checkout Pembayaran via Payment Gateway Eksternal (`POST /api/v1/payments/checkout`)
**Request Body:**
```json
{
  "order_id": "30b4b309-e26f-4a92-8c17-e3a468447cbf",
  "metode_pembayaran": "QRIS"
}
```
**Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Tagihan pembayaran berhasil dibuat melalui Payment Gateway Eksternal. Silakan selesaikan pembayaran agar dana masuk ke Escrow.",
  "data": {
    "payment_id": "8c19e4b2-21b4-4d99-9890-71fb09a1e331",
    "order_id": "30b4b309-e26f-4a92-8c17-e3a468447cbf",
    "metode_pembayaran": "QRIS",
    "nominal": "150000.00",
    "mata_uang": "IDR",
    "status_pembayaran": "Menunggu",
    "status_pembayaran_kode": "pending",
    "status_escrow": "Belum Aktif",
    "status_escrow_kode": "none",
    "referensi_gateway": "SK-GW-30B4B309-1794852465656",
    "snap_token": "snap-ext-9f4a8d2c1e7b3a5f6d8c9e0a",
    "payment_url": "[https://app.sandbox.midtrans.com/snap/v2/vtweb/snap-ext-9f4a8d2c1e7b3a5f6d8c9e0a](https://app.sandbox.midtrans.com/snap/v2/vtweb/snap-ext-9f4a8d2c1e7b3a5f6d8c9e0a)",
    "qr_code_url": "[https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=SAKUSKILL.QRIS.SK-GW-30B4B309-1794852465656.IDR.150000](https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=SAKUSKILL.QRIS.SK-GW-30B4B309-1794852465656.IDR.150000)",
    "va_number": "880852465656",
    "nominal_usd_estimasi": "8.25",
    "ringkasan_escrow": {
      "status_pembayaran": "Menunggu",
      "status_pembayaran_kode": "pending",
      "status_escrow": "Belum Aktif",
      "status_escrow_kode": "none",
      "dana_aman_di_escrow": false,
      "dana_dilepas_ke_penyedia": false,
      "dana_dikembalikan_ke_pelanggan": false
    },
    "instruksi_gateway": {
      "provider": "external_qris_and_midtrans_compatible",
      "referensi_gateway": "SK-GW-30B4B309-1794852465656",
      "metode_pembayaran": "QRIS",
      "snap_token": "snap-ext-9f4a8d2c1e7b3a5f6d8c9e0a",
      "payment_url": "[https://app.sandbox.midtrans.com/snap/v2/vtweb/snap-ext-9f4a8d2c1e7b3a5f6d8c9e0a](https://app.sandbox.midtrans.com/snap/v2/vtweb/snap-ext-9f4a8d2c1e7b3a5f6d8c9e0a)",
      "qr_code_url": "[https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=](https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=)...",
      "va_number": "880852465656",
      "estimasi_usd": "8.25"
    }
  }
}
```

#### 2. Pelunasan & Penahanan Dana di Rekening Bersama (`POST /api/v1/payments/:orderId/simulate-pay`)
**Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Pembayaran berhasil diselesaikan (settlement). Dana kini ditahan dengan aman di Rekening Bersama (Escrow).",
  "data": {
    "order_id": "30b4b309-e26f-4a92-8c17-e3a468447cbf",
    "status_pembayaran": "Berhasil",
    "status_pembayaran_kode": "settlement",
    "status_escrow": "Ditahan",
    "status_escrow_kode": "held",
    "ringkasan_escrow": {
      "status_pembayaran": "Berhasil",
      "status_pembayaran_kode": "settlement",
      "status_escrow": "Ditahan",
      "status_escrow_kode": "held",
      "dana_aman_di_escrow": true,
      "dana_dilepas_ke_penyedia": false,
      "dana_dikembalikan_ke_pelanggan": false
    }
  }
}
```

#### 3. Ringkasan Saldo Rekening Bersama / Escrow (`GET /api/v1/payments/summary`)
**Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Ringkasan Rekening Bersama (Escrow) dan daftar pembayaran berhasil dimuat.",
  "data": [ ... ],
  "meta": {
    "total_dana_ditahan_escrow": "0.00",
    "total_pendapatan_dilepas_penyedia": "150000.00",
    "total_pembayaran_selesai_pelanggan": "0.00",
    "total_dana_dikembalikan_refund": "0.00",
    "total_transaksi_pembayaran": 2
  }
}
```
