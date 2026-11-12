BEGIN;

-- 1. Aktifkan Ekstensi PostGIS & UUID (SKPL Tabel 2.1 & FR-27)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Definisi Tipe Enumerasi Baku Sesuai Label Antarmuka (NFR-22)
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('Penyedia Jasa', 'Pelanggan', 'Administrator');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE verification_status_enum AS ENUM ('Belum Terverifikasi', 'Terverifikasi', 'Ditolak');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE offer_type_enum AS ENUM ('Berbayar', 'Barter', 'Berbayar dan Barter');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE listing_status_enum AS ENUM ('Aktif', 'Nonaktif', 'Disembunyikan Moderasi');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE order_status_enum AS ENUM (
        'Diajukan', 'Ditolak', 'Dalam Negosiasi', 'Disepakati',
        'Dibayar', 'Dikerjakan', 'Menunggu Konfirmasi', 'Selesai',
        'Dibatalkan', 'Dalam Sengketa'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE proposal_status_enum AS ENUM ('Menunggu', 'Disetujui', 'Ditolak');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_enum AS ENUM (
        'Menunggu Pembayaran', 'Menunggu Verifikasi', 'Terverifikasi', 'Gagal', 'Dibatalkan'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE escrow_sim_status_enum AS ENUM (
        'Belum Ada Dana', 'Ditahan (Simulasi)', 'Dilepas (Simulasi)', 'Dikembalikan (Simulasi)'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE barter_status_enum AS ENUM (
        'Diajukan', 'Ditolak', 'Dalam Diskusi', 'Disepakati',
        'Dilaksanakan', 'Selesai', 'Dibatalkan', 'Dalam Sengketa'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE barter_exec_status_enum AS ENUM ('Belum Dimulai', 'Dikerjakan', 'Selesai Dikerjakan');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE transaction_context_enum AS ENUM ('Pesanan', 'Barter');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE review_mod_status_enum AS ENUM ('Tampil', 'Disembunyikan');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE report_target_enum AS ENUM ('Pengguna', 'Listing', 'Ulasan', 'Pesan', 'Pesanan', 'Barter');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE report_status_enum AS ENUM ('Baru', 'Ditinjau', 'Selesai');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3. Tabel Users (Konstruksi 1 - Tabel 3.32)
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    kata_sandi_hash TEXT NOT NULL,
    peran user_role_enum NOT NULL DEFAULT 'Pelanggan',
    status_verifikasi verification_status_enum NOT NULL DEFAULT 'Belum Terverifikasi',
    deskripsi_profil TEXT,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Tabel Skills (Konstruksi 2 - Tabel 3.33)
CREATE TABLE IF NOT EXISTS skills (
    skill_id SERIAL PRIMARY KEY,
    nama_keterampilan VARCHAR(100) NOT NULL UNIQUE,
    kategori VARCHAR(100) NOT NULL
);

-- 5. Tabel ProviderSkills (Konstruksi 3 - Tabel 3.34)
CREATE TABLE IF NOT EXISTS provider_skills (
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    skill_id INT NOT NULL REFERENCES skills(skill_id) ON DELETE RESTRICT,
    PRIMARY KEY (user_id, skill_id)
);

-- 6. Tabel PortfolioItems (Konstruksi 4 - Tabel 3.35)
CREATE TABLE IF NOT EXISTS portfolio_items (
    portfolio_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    penyedia_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    judul VARCHAR(200) NOT NULL,
    deskripsi TEXT NOT NULL,
    berkas_ref TEXT NOT NULL,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Tabel ServiceListings / Gigs (Konstruksi 5 - Tabel 3.36, FR-18, FR-21, NFR-39)
CREATE TABLE IF NOT EXISTS service_listings (
    listing_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    penyedia_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    skill_id INT NOT NULL REFERENCES skills(skill_id) ON DELETE RESTRICT,
    judul VARCHAR(200) NOT NULL,
    deskripsi TEXT NOT NULL,
    harga NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (harga >= 0),
    lokasi GEOGRAPHY(Point, 4326) NOT NULL,
    tipe_penawaran offer_type_enum NOT NULL DEFAULT 'Berbayar',
    deskripsi_imbalan_barter TEXT,
    status listing_status_enum NOT NULL DEFAULT 'Aktif',
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diubah_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_listings_lokasi ON service_listings USING GIST (lokasi);
CREATE INDEX IF NOT EXISTS idx_service_listings_status_tipe ON service_listings (status, tipe_penawaran);

-- 8. Tabel Orders (Konstruksi 6 - Tabel 3.37, FR-34, NFR-39)
CREATE TABLE IF NOT EXISTS orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES service_listings(listing_id) ON DELETE RESTRICT,
    pembeli_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    penyedia_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    deskripsi_kebutuhan TEXT NOT NULL,
    ruang_lingkup_disepakati TEXT,
    harga_disepakati NUMERIC(12, 2) CHECK (harga_disepakati >= 0),
    tenggat TIMESTAMPTZ,
    status_pesanan order_status_enum NOT NULL DEFAULT 'Diajukan',
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diperbarui_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_order_bukan_milik_sendiri CHECK (pembeli_id <> penyedia_id)
);

-- 9. Tabel OrderProposals (Konstruksi 7 - Tabel 3.38)
CREATE TABLE IF NOT EXISTS order_proposals (
    proposal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    pengusul_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    ruang_lingkup TEXT NOT NULL,
    harga NUMERIC(12, 2) NOT NULL CHECK (harga >= 0),
    tenggat TIMESTAMPTZ NOT NULL,
    status_usulan proposal_status_enum NOT NULL DEFAULT 'Menunggu',
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. Tabel Payments (Konstruksi 8 - Tabel 3.39, NFR-37, NFR-39)
CREATE TABLE IF NOT EXISTS payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
    jumlah_pembayaran NUMERIC(12, 2) NOT NULL CHECK (jumlah_pembayaran >= 0),
    rujukan_gateway VARCHAR(255) UNIQUE,
    status_pembayaran payment_status_enum NOT NULL DEFAULT 'Menunggu Pembayaran',
    status_dana_simulasi escrow_sim_status_enum NOT NULL DEFAULT 'Belum Ada Dana',
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diverifikasi_pada TIMESTAMPTZ
);

-- 11. Tabel BarterAgreements (Konstruksi 10 - Tabel 3.41, FR-70, FR-77)
CREATE TABLE IF NOT EXISTS barter_agreements (
    barter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pihak_1 UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    pihak_2 UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    listing_id UUID REFERENCES service_listings(listing_id) ON DELETE RESTRICT,
    deskripsi_kontribusi_pihak_1 TEXT NOT NULL,
    deskripsi_kontribusi_pihak_2 TEXT,
    tenggat_pihak_1 TIMESTAMPTZ,
    tenggat_pihak_2 TIMESTAMPTZ,
    konfirmasi_kesepakatan_pihak_1 BOOLEAN NOT NULL DEFAULT FALSE,
    konfirmasi_kesepakatan_pihak_2 BOOLEAN NOT NULL DEFAULT FALSE,
    status_pelaksanaan_pihak_1 barter_exec_status_enum NOT NULL DEFAULT 'Belum Dimulai',
    status_pelaksanaan_pihak_2 barter_exec_status_enum NOT NULL DEFAULT 'Belum Dimulai',
    konfirmasi_selesai_pihak_1 BOOLEAN NOT NULL DEFAULT FALSE,
    konfirmasi_selesai_pihak_2 BOOLEAN NOT NULL DEFAULT FALSE,
    status barter_status_enum NOT NULL DEFAULT 'Diajukan',
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diperbarui_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_barter_bukan_diri_sendiri CHECK (pihak_1 <> pihak_2)
);

-- 12. Tabel Messages (Konstruksi 9 - Tabel 3.40)
CREATE TABLE IF NOT EXISTS messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    konteks_tipe transaction_context_enum NOT NULL,
    konteks_id UUID NOT NULL,
    pengirim_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    isi_pesan TEXT NOT NULL,
    dikirim_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_konteks ON messages (konteks_tipe, konteks_id, dikirim_pada);

-- 13. Tabel Reviews (Konstruksi 11 - Tabel 3.42, FR-85, NFR-38)
CREATE TABLE IF NOT EXISTS reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaksi_tipe transaction_context_enum NOT NULL,
    transaksi_id UUID NOT NULL,
    pemberi_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    penerima_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rating_kualitas SMALLINT NOT NULL CHECK (rating_kualitas BETWEEN 1 AND 5),
    rating_ketepatan_waktu SMALLINT NOT NULL CHECK (rating_ketepatan_waktu BETWEEN 1 AND 5),
    komentar TEXT,
    status_moderasi review_mod_status_enum NOT NULL DEFAULT 'Tampil',
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_satu_ulasan_per_pemberi_per_transaksi UNIQUE (transaksi_tipe, transaksi_id, pemberi_id),
    CONSTRAINT chk_review_bukan_diri_sendiri CHECK (pemberi_id <> penerima_id)
);

-- 14. Tabel Reports (Konstruksi 12 - Tabel 3.43)
CREATE TABLE IF NOT EXISTS reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pelapor_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    target_tipe report_target_enum NOT NULL,
    target_id UUID NOT NULL,
    alasan VARCHAR(255) NOT NULL,
    keterangan TEXT NOT NULL,
    status_penanganan report_status_enum NOT NULL DEFAULT 'Baru',
    keputusan TEXT,
    ditangani_oleh UUID REFERENCES users(user_id) ON DELETE RESTRICT,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diselesaikan_pada TIMESTAMPTZ
);

-- 15. Tabel AuditLogs (Konstruksi 13 - Tabel 3.44, NFR-11 Append-Only)
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aktor_id UUID REFERENCES users(user_id) ON DELETE RESTRICT,
    aksi VARCHAR(150) NOT NULL,
    objek_tipe VARCHAR(50) NOT NULL,
    objek_id UUID NOT NULL,
    status_sebelum VARCHAR(100),
    status_sesudah VARCHAR(100),
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed Kategori & Keterampilan Awal sesuai Prioritas MVP (SKPL FR-23)
INSERT INTO skills (nama_keterampilan, kategori) VALUES
    ('Instalasi OS & Perbaikan Laptop', 'Jasa Teknis'),
    ('Debugging & Pembuatan Web Sederhana', 'Jasa Teknis'),
    ('Desain UI/UX & Grafis Poster', 'Desain'),
    ('Fotografi Wisuda & Kegiatan Kampus', 'Fotografi'),
    ('Bimbingan Belajar Pemrograman Dasar', 'Bimbingan Belajar')
ON CONFLICT (nama_keterampilan) DO NOTHING;

COMMIT;
