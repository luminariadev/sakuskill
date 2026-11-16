BEGIN;

DROP TABLE IF EXISTS payments CASCADE;

CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE,
    pelanggan_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    penyedia_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    metode_pembayaran VARCHAR(50) NOT NULL DEFAULT 'QRIS',
    nominal NUMERIC(12,2) NOT NULL CHECK (nominal >= 0),
    mata_uang VARCHAR(10) NOT NULL DEFAULT 'IDR',
    status_pembayaran VARCHAR(30) NOT NULL DEFAULT 'Menunggu',
    status_pembayaran_kode VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (
      status_pembayaran_kode IN ('pending', 'settlement', 'failed', 'expired', 'refunded')
    ),
    status_escrow VARCHAR(30) NOT NULL DEFAULT 'Belum Aktif',
    status_escrow_kode VARCHAR(30) NOT NULL DEFAULT 'none' CHECK (
      status_escrow_kode IN ('none', 'held', 'released', 'refunded')
    ),
    gateway_provider VARCHAR(50) NOT NULL DEFAULT 'midtrans_external',
    referensi_gateway VARCHAR(120) UNIQUE NOT NULL,
    snap_token VARCHAR(255),
    payment_url VARCHAR(500),
    qr_code_url VARCHAR(500),
    va_number VARCHAR(100),
    kurs_usd_referensi NUMERIC(16,8),
    nominal_usd_estimasi NUMERIC(12,2),
    raw_gateway_response JSONB NOT NULL DEFAULT '{}'::jsonb,
    catatan_escrow TEXT,
    dibayar_pada TIMESTAMPTZ,
    escrow_dilepas_pada TIMESTAMPTZ,
    escrow_dikembalikan_pada TIMESTAMPTZ,
    kedaluwarsa_pada TIMESTAMPTZ,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diubah_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_pelanggan ON payments(pelanggan_id);
CREATE INDEX idx_payments_penyedia ON payments(penyedia_id);
CREATE INDEX idx_payments_ref ON payments(referensi_gateway);

COMMIT;