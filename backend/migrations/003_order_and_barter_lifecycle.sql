BEGIN;

-- Bangun ulang tabel transaksi (orders, order_proposals, barter_agreements, barter_confirmations, reviews)
-- agar seluruh kolom sesuai dengan spesifikasi Order Lifecycle & Barter Lifecycle API
DROP TABLE IF EXISTS barter_confirmations CASCADE;
DROP TABLE IF EXISTS order_proposals CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS barter_agreements CASCADE;
DROP TABLE IF EXISTS orders CASCADE;

-- 1. Tabel Orders (Kerjaan #1 s.d. #5: Snapshot Gig, Scope, Harga Final, Deadline, Lifecycle Status)
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES service_listings(listing_id) ON DELETE RESTRICT,
    pelanggan_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    penyedia_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    snapshot_judul VARCHAR(200) NOT NULL,
    snapshot_harga NUMERIC(12,2) NOT NULL DEFAULT 0,
    snapshot_ketentuan TEXT,
    catatan_kebutuhan TEXT NOT NULL DEFAULT '',
    ruang_lingkup TEXT NOT NULL,
    harga_kesepakatan NUMERIC(12,2) NOT NULL CHECK (harga_kesepakatan >= 0),
    tenggat_pekerjaan TIMESTAMPTZ NOT NULL,
    status_pesanan VARCHAR(40) NOT NULL DEFAULT 'Diajukan',
    status_kode VARCHAR(40) NOT NULL DEFAULT 'requested' CHECK (
      status_kode IN ('requested', 'negotiating', 'accepted', 'in_progress', 'completion_requested', 'completed', 'rejected', 'cancelled')
    ),
    alasan_pembatalan TEXT,
    dikonfirmasi_selesai_pada TIMESTAMPTZ,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diubah_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tabel Order Proposals (Negosiasi Scope, Harga, dan Tenggat)
CREATE TABLE order_proposals (
    proposal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    pengaju_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    harga_tawaran NUMERIC(12,2) NOT NULL CHECK (harga_tawaran >= 0),
    deskripsi_ruang_lingkup TEXT NOT NULL,
    tenggat_usulan TIMESTAMPTZ,
    status_proposal VARCHAR(30) NOT NULL DEFAULT 'Menunggu' CHECK (
      status_proposal IN ('Menunggu', 'Disetujui', 'Ditolak')
    ),
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Tabel Barter Agreements (Kerjaan #6 s.d. #10: 2 Pengguna, Jasa Ditukar, Tenggat, Dual-Consent & Dual-Confirmation)
CREATE TABLE barter_agreements (
    barter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES service_listings(listing_id) ON DELETE RESTRICT,
    listing_pengaju_id UUID REFERENCES service_listings(listing_id) ON DELETE SET NULL,
    pengaju_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    penerima_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    deskripsi_jasa_pengaju TEXT NOT NULL,
    deskripsi_jasa_penerima TEXT NOT NULL,
    tenggat_pekerjaan TIMESTAMPTZ NOT NULL,
    setuju_pengaju BOOLEAN NOT NULL DEFAULT TRUE,
    setuju_penerima BOOLEAN NOT NULL DEFAULT FALSE,
    konfirmasi_selesai_pengaju BOOLEAN NOT NULL DEFAULT FALSE,
    konfirmasi_selesai_penerima BOOLEAN NOT NULL DEFAULT FALSE,
    waktu_konfirmasi_pengaju TIMESTAMPTZ,
    waktu_konfirmasi_penerima TIMESTAMPTZ,
    status VARCHAR(40) NOT NULL DEFAULT 'Diajukan',
    status_kode VARCHAR(40) NOT NULL DEFAULT 'requested' CHECK (
      status_kode IN ('requested', 'negotiating', 'accepted', 'in_progress', 'completion_requested', 'completed', 'rejected', 'cancelled')
    ),
    alasan_pembatalan TEXT,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diubah_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Tabel Barter Confirmations (Pencatatan Konfirmasi Masing-Masing Pihak - Kerjaan #9)
CREATE TABLE barter_confirmations (
    confirmation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barter_id UUID NOT NULL REFERENCES barter_agreements(barter_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    peran_dalam_barter VARCHAR(20) NOT NULL DEFAULT 'Partisipan',
    catatan TEXT,
    status_konfirmasi BOOLEAN NOT NULL DEFAULT TRUE,
    dikonfirmasi_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (barter_id, user_id)
);

-- 5. Tabel Reviews (Kerjaan #5: Review Hanya Setelah Order/Barter Selesai)
CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaksi_tipe VARCHAR(20) NOT NULL DEFAULT 'Order' CHECK (transaksi_tipe IN ('Order', 'Barter')),
    order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
    barter_id UUID REFERENCES barter_agreements(barter_id) ON DELETE CASCADE,
    pemberi_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    penerima_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rating_kualitas SMALLINT CHECK (rating_kualitas BETWEEN 1 AND 5),
    rating_ketepatan_waktu SMALLINT CHECK (rating_ketepatan_waktu BETWEEN 1 AND 5),
    komentar TEXT,
    status_moderasi VARCHAR(30) NOT NULL DEFAULT 'Tampil' CHECK (
      status_moderasi IN ('Tampil', 'Disembunyikan Moderasi')
    ),
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_pelanggan ON orders(pelanggan_id);
CREATE INDEX idx_orders_penyedia ON orders(penyedia_id);
CREATE INDEX idx_orders_listing ON orders(listing_id);
CREATE INDEX idx_barter_pengaju ON barter_agreements(pengaju_id);
CREATE INDEX idx_barter_penerima ON barter_agreements(penerima_id);
CREATE INDEX idx_reviews_penerima ON reviews(penerima_id);

COMMIT;
