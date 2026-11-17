# Dokumentasi Simulasi Pembayaran MVP SakuSkill (`[P0][BE]`)

**PIC:** Arya Fabio (BE), dukungan Rifqi Bilal | **Prioritas:** P0

---

## 1. Pernyataan Keterbatasan MVP (Wajib Diketahui Tim & Penguji)

> **PERINGATAN KETERBATASAN MVP (KERJAAN #8):**
> 1. **Bukan Uang Sungguhan:** Seluruh nominal transaksi pada modul `/api/v1/payments` hanyalah angka simulasi di basis data untuk keperluan demonstrasi alur MVP SakuSkill.
> 2. **Bukan Escrow Perbankan Nyata:** Sistem tidak menahan dana di rekening bank atau lembaga keuangan mana pun.
> 3. **Integrasi Midtrans Ditunda:** Sesuai keputusan produk MVP, tidak ada pemanggilan API eksternal Midtrans pada rilis MVP ini. Integrasi Payment Gateway pihak ketiga ditunda ke fase pengembangan pasca-MVP.

---

## 2. Pemisahan Status Payment & Status Order

Tabel `payments` dan tabel `orders` memiliki siklus hidup yang **terpisah** (`status_kode` masing-masing tidak saling menimpa):

| Entitas Tabel | Kolom Status | Nilai Status yang Didukung | Penentu Status |
| :--- | :--- | :--- | :--- |
| **`payments`** | `status_kode` (`status_pembayaran`) | `pending` (`Menunggu`), `success` (`Berhasil`), `failed` (`Gagal`) | Ditetapkan murni oleh Backend melalui state machine simulasi |
| **`orders`** | `status_kode` (`status_pesanan`) | `requested`, `negotiating`, `accepted`, `in_progress`, `completion_requested`, `completed`, `rejected`, `cancelled` | Ditetapkan oleh aksi Pelanggan & Penyedia Jasa |

**Aturan Ketergantungan Order terhadap Payment (Kerjaan #6 & #7):**
* Order hanya dapat dibuatkan sesi pembayaran ketika berstatus `accepted` (`Disepakati`).
* Penyedia jasa **hanya boleh** mengubah status order dari `accepted` menjadi `in_progress` apabila `payments.status_kode === "success"`.
* Apabila pembayaran masih `pending` atau berakhir `failed`, maka pemanggilan `POST /api/v1/orders/:id/start` ditolak oleh server (`400 PAYMENT_REQUIRED_BEFORE_START`) dan status order **tetap `accepted`** (tidak berubah menjadi `in_progress`).

---

## 3. Daftar Endpoint Simulasi Pembayaran MVP

| Method & Path | Aktor yang Diizinkan | Pembatasan Environment | Deskripsi & Aturan Backend |
| :--- | :--- | :--- | :--- |
| `POST /api/v1/payments` | Hanya Pelanggan Terkait | Semua Environment | Membuat (atau me-reset setelah `failed`) record payment dengan status awal **`pending`**. Menolak `400 CLIENT_CANNOT_FORCE_STATUS` jika client mengirim field `status`. |
| `POST /api/v1/payments/:orderId/simulate-success` | Hanya Pelanggan Terkait | Khusus `development` / `demo` / `test` | Mengubah status payment dari **`pending` -> `success`**. Status order tetap `accepted` dan siap dilanjutkan ke `in_progress`. |
| `POST /api/v1/payments/:orderId/simulate-failed` | Hanya Pelanggan Terkait | Khusus `development` / `demo` / `test` | Mengubah status payment dari **`pending` -> `failed`**. Order tertahan di `accepted` dan tidak bisa lanjut ke `in_progress`. |
| `PATCH /api/v1/payments/:orderId/status` | Ditolak Server | Semua Environment | Selalu mengembalikan `400 CLIENT_CANNOT_FORCE_STATUS` sebagai bukti client tidak bisa memaksa status secara langsung. |
| `GET /api/v1/payments/:orderId` | Pelanggan & Penyedia Terkait | Semua Environment | Menampilkan detail record payment, status relasi order, dan objek `disclaimer_mvp`. |
| `GET /api/v1/payments` | Pengguna Login | Semua Environment | Menampilkan seluruh riwayat simulasi pembayaran milik pengguna. |

---

## 4. Contoh Alur Demonstrasi: Alur Gagal (`pending -> failed`) vs Alur Sukses (`pending -> success`)

### A. Contoh Alur Gagal (`pending -> failed`)
1. **Pelanggan memulai sesi pembayaran (`POST /api/v1/payments`):**
   ```json
   { "order_id": "<uuid_order_accepted>", "metode_simulasi": "SIMULASI_MVP" }
   ```
   *Respons Backend (`201 Created`):* `payment.status_kode = "pending"`, `order_status_kode = "accepted"`.
2. **Pelanggan mensimulasikan kegagalan (`POST /api/v1/payments/:orderId/simulate-failed`):**
   ```json
   { "alasan_gagal": "Simulasi kegagalan pembayaran untuk demo MVP." }
   ```
   *Respons Backend (`200 OK`):* `payment.status_kode = "failed"`, `order_status_kode = "accepted"`, `boleh_lanjut_in_progress = false`.
3. **Penyedia mencoba memulai pekerjaan (`POST /api/v1/orders/:orderId/start`):**
   *Respons Backend (`400 Bad Request`):* Ditolak dengan kode `PAYMENT_REQUIRED_BEFORE_START`. Order terbukti **tidak berubah** menjadi `in_progress`.

### B. Contoh Alur Sukses (`pending -> success`)
1. **Pelanggan mengulangi inisiasi pembayaran (`POST /api/v1/payments`):**
   *Respons Backend (`201 Created`):* Record payment di-reset ke `status_kode = "pending"` (`jumlah_percobaan = 2`).
2. **Pelanggan mensimulasikan pembayaran sukses (`POST /api/v1/payments/:orderId/simulate-success`):**
   ```json
   { "catatan": "Simulasi pembayaran MVP berhasil." }
   ```
   *Respons Backend (`200 OK`):* `payment.status_kode = "success"`, `order_status_kode = "accepted"`, `boleh_lanjut_in_progress = true`.
3. **Penyedia memulai pengerjaan order (`POST /api/v1/orders/:orderId/start`):**
   *Respons Backend (`200 OK`):* `order.status_kode` berubah menjadi `"in_progress"`, sementara `payment.status_kode` tetap `"success"`.