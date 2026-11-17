BEGIN;

DROP TABLE IF EXISTS payments CASCADE;

-- Kerjaan #1, #2, #8: Tabel payments terpisah dari orders dengan status pending, success, failed
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE,
    pelanggan_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    penyedia_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    metode_simulasi VARCHAR(50) NOT NULL DEFAULT 'SIMULASI_MVP',
    nominal NUMERIC(12,2) NOT NULL CHECK (nominal >= 0),
    mata_uang VARCHAR(10) NOT NULL DEFAULT 'IDR',
    status_kode VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (
      status_kode IN ('pending', 'success', 'failed')
    ),
    status_pembayaran VARCHAR(30) NOT NULL DEFAULT 'Menunggu' CHECK (
      status_pembayaran IN ('Menunggu', 'Berhasil', 'Gagal')
    ),
    referensi_simulasi VARCHAR(100) UNIQUE NOT NULL,
    catatan_simulasi TEXT,
    jumlah_percobaan INT NOT NULL DEFAULT 1,
    is_simulasi_mvp BOOLEAN NOT NULL DEFAULT TRUE,
    disimulasikan_pada TIMESTAMPTZ,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    diubah_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_pelanggan_id ON payments(pelanggan_id);
CREATE INDEX idx_payments_penyedia_id ON payments(penyedia_id);
CREATE INDEX idx_payments_status_kode ON payments(status_kode);

COMMIT;