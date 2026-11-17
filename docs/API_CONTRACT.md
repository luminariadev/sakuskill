# SakuSkill Backend API Contract (v1.3 MVP ? Task 1, 2, 3 & 4 Simulasi Pembayaran)

Dokumen ini adalah acuan integrasi resmi bagi tim **Mobile Flutter** untuk mengakses seluruh modul Backend SakuSkill: **Auth, User Profile, Gigs CRUD, Hyperlocal Discovery (PostGIS), Order Lifecycle, Barter Lifecycle, serta Simulasi Pembayaran MVP**.

> **CATATAN KETERBATASAN MVP (Wajib Ditampilkan/Diketahui Tim Frontend & Penguji):**
> 1. **Bukan Uang Sungguhan:** Seluruh nominal pada modul `/api/v1/payments` adalah simulasi internal untuk keperluan demonstrasi MVP.
> 2. **Bukan Escrow Perbankan Nyata:** Sistem tidak menahan dana di rekening bank atau lembaga keuangan mana pun.
> 3. **Integrasi Midtrans Ditunda:** Sesuai keputusan produk MVP, tidak ada pemanggilan API Midtrans pada fase ini.

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
| `400` | `INVALID_ORDER_STATE_FOR_PAYMENT` | Mencoba memulai simulasi pembayaran saat order belum berstatus `accepted` |
| `400` | `CLIENT_CANNOT_FORCE_STATUS` | Client mengirim field `status`/`status_kode` pada body atau memanggil PATCH status secara langsung |
| `400` | `INVALID_PAYMENT_TRANSITION` | Mencoba simulasi `success`/`failed` ketika status payment bukan `pending` |
| `400` | `PAYMENT_REQUIRED_BEFORE_START` | Penyedia mencoba memulai order (`in_progress`) saat payment belum ada, masih `pending`, atau `failed` |
| `401` | `UNAUTHORIZED` / `TOKEN_REVOKED` | Token JWT tidak ada, kedaluwarsa, atau sudah di-logout |
| `403` | `FORBIDDEN_NOT_OWNER` | Mencoba mengubah/menghapus gig milik pengguna lain |
| `403` | `FORBIDDEN_NOT_PARTICIPANT` | Pengguna di luar transaksi mencoba mengakses/mengubah Order, Barter, atau Payment |
| `403` | `FORBIDDEN_ONLY_CUSTOMER` | Penyedia jasa atau pengguna luar mencoba memulai/menjalankan simulasi pembayaran |
| `403` | `SIMULATION_DISABLED_IN_PRODUCTION` | Endpoint simulasi dipanggil pada environment production tanpa izin |
| `404` | `GIG_NOT_FOUND` / `ORDER_NOT_FOUND` / `BARTER_NOT_FOUND` / `PAYMENT_NOT_FOUND` | Data dengan UUID tersebut tidak ditemukan |
| `409` | `EMAIL_ALREADY_EXISTS` / `REVIEW_ALREADY_EXISTS` / `PAYMENT_ALREADY_SUCCESS` | Duplikasi email, ulasan, atau pembayaran sudah berstatus `success` |
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

## 4. Pemetaan Enum Status Terpisah: Order, Barter & Payment (Task 3 & 4)

Status pada tabel **`orders`** dan tabel **`payments`** disimpan secara **terpisah** dan tidak saling menimpa:

### A. Status Order & Barter (`orders.status_kode` / `barter_agreements.status_kode`)
| `status_kode` (State Machine) | Label UI (`status_pesanan` / `status`) | Fase Transaksi | Keterangan Status |
| :--- | :--- | :--- | :--- |
| `requested` | `Diajukan` | Awal | Order atau penawaran barter baru dibuat, menunggu respons penyedia/penerima |
| `negotiating` | `Dalam Negosiasi` | Aktif | Sedang dalam pengajuan revisi scope, harga, atau tenggat waktu |
| `accepted` | `Disepakati` | Aktif | Disetujui penyedia (Order) atau disetujui kedua belah pihak (Barter) |
| `in_progress` | `Dikerjakan` | Aktif | Pekerjaan sedang berlangsung (Untuk Order: **wajib `payment.status_kode === "success"`**) |
| `completion_requested` | `Menunggu Konfirmasi` | Aktif | Penyedia mengajukan klaim selesai (Order) atau baru 1 pihak konfirmasi selesai (Barter) |
| `completed` | `Selesai` | Terminal | Pelanggan mengonfirmasi selesai (Order) atau kedua pihak telah konfirmasi selesai (Barter) |
| `rejected` | `Ditolak` | Terminal | Penawaran ditolak oleh penyedia/penerima sebelum disepakati |
| `cancelled` | `Dibatalkan` | Terminal | Transaksi dibatalkan sebelum pengerjaan dimulai (`in_progress`) |

### B. Status Simulasi Pembayaran MVP (`payments.status_kode`)
| `status_kode` (State Machine) | Label UI (`status_pembayaran`) | Penentu Status | Dampak terhadap Order |
| :--- | :--- | :--- | :--- |
| `pending` | `Menunggu` | Ditetapkan otomatis oleh Backend saat `POST /payments` | Order tertahan di `accepted`, belum boleh masuk `in_progress` |
| `failed` | `Gagal` | Ditetapkan oleh Backend saat `POST /payments/:orderId/simulate-failed` | Order tetap `accepted` (**tidak** berubah menjadi `in_progress`). Pelanggan dapat mengulang `POST /payments` |
| `success` | `Berhasil` | Ditetapkan oleh Backend saat `POST /payments/:orderId/simulate-success` | Order tetap `accepted` (terpisah), namun kini **diizinkan** lanjut ke `in_progress` oleh Penyedia |

---

## 5. Spesifikasi Endpoint Order Lifecycle (`/api/v1/orders`)

| Method & Path | Aktor yang Diizinkan | Transisi Status | Keterangan & Aturan Pembayaran MVP |
| :--- | :--- | :--- | :--- |
| `POST /orders` | Pelanggan | `-> requested` | Membuat order dari gig dengan snapshot harga & ketentuan otomatis |
| `GET /orders` | Partisipan | - | Daftar order milik pengguna (`?role=pelanggan\|penyedia&status=...`) |
| `GET /orders/:id` | Partisipan | - | Detail order beserta `snapshot_gig`, `kesepakatan`, `proposals`, `reviews`, dan objek `payment` terpisah |
| `POST /orders/:id/proposals` | Pelanggan / Penyedia | `-> negotiating` | Mengajukan penyesuaian scope, harga tawaran, dan usulan deadline |
| `POST /orders/:id/accept` | Penyedia Jasa | `-> accepted` | Menyetujui order dan mengunci kesepakatan scope, harga final, serta deadline |
| `POST /orders/:id/reject` | Penyedia Jasa | `-> rejected` | Menolak order yang berstatus `requested` atau `negotiating` |
| `POST /orders/:id/start` | Penyedia Jasa | `accepted -> in_progress` | Memulai pengerjaan (**Wajib `payment.status_kode === "success"`, jika belum maka ditolak `400 PAYMENT_REQUIRED_BEFORE_START`**) |
| `POST /orders/:id/request-completion` | Penyedia Jasa | `in_progress -> completion_requested` | Penyedia mengajukan klaim bahwa pekerjaan telah selesai |
| `POST /orders/:id/complete` | Pelanggan | `completion_requested -> completed` | Pelanggan mengonfirmasi pekerjaan telah selesai |
| `POST /orders/:id/cancel` | Pelanggan | `-> cancelled` | Membatalkan order sebelum `in_progress` |
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

## 7. Spesifikasi Endpoint Simulasi Pembayaran MVP (`/api/v1/payments`)

### A. Diagram Alur Simulasi Sukses & Gagal (Status Payment Terpisah dari Order)
```text
1. Penyedia menyetujui Order (orders.status_kode = "accepted")
2. Pelanggan memulai simulasi pembayaran (POST /api/v1/payments)
   ??> Jangan kirim field "status" dari client! (Jika dikirim -> Ditolak 400 CLIENT_CANNOT_FORCE_STATUS)
   ??> Backend membuat record payment terpisah dengan status_kode = "pending" (Order tetap "accepted")
3A. Skenario Alur Gagal (POST /api/v1/payments/:orderId/simulate-failed):
   ??> Backend mengubah payments.status_kode menjadi "failed"
   ??> orders.status_kode tetap "accepted" (TIDAK berubah menjadi "in_progress")
   ??> Jika Penyedia memanggil POST /orders/:id/start -> Ditolak 400 PAYMENT_REQUIRED_BEFORE_START
3B. Skenario Alur Sukses (POST /api/v1/payments/:orderId/simulate-success):
   ??> (Jika sebelumnya failed, Pelanggan panggil POST /api/v1/payments dulu untuk reset ke "pending")
   ??> Backend mengubah payments.status_kode menjadi "success"
   ??> orders.status_kode tetap "accepted" (status payment & order tetap terpisah)
   ??> Penyedia memanggil POST /orders/:id/start -> Berhasil! orders.status_kode berubah menjadi "in_progress"
```

### B. Daftar Endpoint Simulasi Pembayaran MVP

| Method & Path | Aktor | Pembatasan Env | Keterangan |
| :--- | :--- | :--- | :--- |
| `POST /payments` (atau `/payments/checkout`) | Hanya Pelanggan Terkait | Semua Env | Membuat (atau me-reset setelah `failed`) record payment dengan status awal `pending` yang ditetapkan backend |
| `POST /payments/:orderId/simulate-success` (atau `/simulate-pay`) | Hanya Pelanggan Terkait | Khusus `development` / `demo` / `test` | Mengubah status payment dari `pending` ke `success`. Mengizinkan order lanjut ke `in_progress` |
| `POST /payments/:orderId/simulate-failed` | Hanya Pelanggan Terkait | Khusus `development` / `demo` / `test` | Mengubah status payment dari `pending` ke `failed`. Menahan order agar tidak bisa masuk `in_progress` |
| `PATCH /payments/:orderId/status` | Ditolak Server (`400`) | Semua Env | Selalu ditolak `400 CLIENT_CANNOT_FORCE_STATUS` karena client tidak boleh memaksa status secara langsung |
| `GET /payments/:orderId` | Pelanggan & Penyedia | Semua Env | Mengambil detail record payment, objek `relasi_order`, dan objek `disclaimer_mvp` |
| `GET /payments` | Pengguna Login | Semua Env | Mengambil daftar seluruh simulasi pembayaran yang melibatkan pengguna |

### C. Contoh Request & Response Simulasi Pembayaran MVP

#### 1. Memulai Sesi Simulasi Pembayaran (`POST /api/v1/payments`)
**Request Body (Jangan menyertakan field `status`!):**
```json
{
  "order_id": "66e64100-cccd-4023-b19c-4e9089283b5d",
  "metode_simulasi": "SIMULASI_MVP",
  "catatan": "Memulai simulasi pembayaran untuk order layanan."
}
```
**Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Record pembayaran simulasi MVP berhasil dibuat dengan status awal pending (ditetapkan oleh backend).",
  "data": {
    "payment_id": "9a41d8c2-11e4-4c88-a120-55bc09e1f221",
    "order_id": "66e64100-cccd-4023-b19c-4e9089283b5d",
    "pelanggan_id": "...",
    "penyedia_id": "...",
    "metode_simulasi": "SIMULASI_MVP",
    "nominal": "120000.00",
    "mata_uang": "IDR",
    "status_kode": "pending",
    "status_pembayaran": "Menunggu",
    "referensi_simulasi": "SIM-MVP-66E64100-1794853000123",
    "jumlah_percobaan": 1,
    "relasi_order": {
      "order_id": "66e64100-cccd-4023-b19c-4e9089283b5d",
      "order_status_kode": "accepted",
      "order_status_label": "Disepakati",
      "boleh_lanjut_in_progress": false
    },
    "disclaimer_mvp": {
      "is_simulasi_mvp": true,
      "bukan_uang_sungguhan": true,
      "bukan_escrow_nyata": true,
      "midtrans_ditunda": true,
      "keterangan": "Simulasi pembayaran internal khusus MVP SakuSkill. Tidak melibatkan uang sungguhan, bukan rekening bersama (escrow) perbankan nyata, dan integrasi Midtrans ditunda pasca-MVP."
    }
  }
}
```

#### 2. Simulasi Pembayaran Gagal (`POST /api/v1/payments/:orderId/simulate-failed`)
**Request Body:**
```json
{
  "alasan_gagal": "Simulasi saldo tidak mencukupi untuk demonstrasi alur gagal."
}
```
**Response (`200 OK`):**
* `data.status_kode` berubah menjadi `"failed"` (`"Gagal"`).
* `data.relasi_order.order_status_kode` tetap `"accepted"` dan `boleh_lanjut_in_progress` bernilai `false`.

#### 3. Simulasi Pembayaran Sukses (`POST /api/v1/payments/:orderId/simulate-success`)
**Request Body:**
```json
{
  "catatan": "Simulasi pembayaran MVP berhasil dilunasi."
}
```
**Response (`200 OK`):**
* `data.status_kode` berubah menjadi `"success"` (`"Berhasil"`).
* `data.relasi_order.order_status_kode` tetap `"accepted"` (terpisah dari status payment), dan `boleh_lanjut_in_progress` berubah menjadi `true` sehingga Penyedia Jasa dapat menekan tombol Mulai Kerjakan (`POST /api/v1/orders/:id/start`).
