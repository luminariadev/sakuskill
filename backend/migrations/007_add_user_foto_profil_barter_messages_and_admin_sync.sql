BEGIN;

-- 1. Sinkronisasi kolom foto_profil (mobile avatar upload) + status/catatan sanksi akun (web admin)
ALTER TABLE users ADD COLUMN IF NOT EXISTS foto_profil TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status_akun VARCHAR(60) NOT NULL DEFAULT 'Aktif';
ALTER TABLE users ADD COLUMN IF NOT EXISTS catatan_sanksi TEXT;

-- 2. Pastikan tabel barter_messages tersedia sebelum fitur chat barter diakses
CREATE TABLE IF NOT EXISTS barter_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barter_id UUID NOT NULL REFERENCES barter_agreements(barter_id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    isi_pesan TEXT NOT NULL,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_barter_messages_barter_id ON barter_messages(barter_id);

-- 3. Izinkan status_kode 'disputed' pada tabel orders agar sejalan dengan status_pesanan 'Dalam Sengketa'
DO $$
DECLARE
    con_name TEXT;
BEGIN
    SELECT c.conname
    INTO con_name
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE t.relname = 'orders'
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) LIKE '%status_kode%';

    IF con_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE orders DROP CONSTRAINT %I', con_name);
    END IF;
END $$;

ALTER TABLE orders
    ADD CONSTRAINT orders_status_kode_check CHECK (
        status_kode IN (
            'requested',
            'negotiating',
            'accepted',
            'in_progress',
            'completion_requested',
            'completed',
            'rejected',
            'cancelled',
            'disputed'
        )
    );

-- 4. Seed akun Administrator default jika belum ada di basis data (password: admin1234)
INSERT INTO users (
    nama,
    email,
    kata_sandi_hash,
    peran,
    status_verifikasi,
    deskripsi_profil,
    status_akun
) VALUES (
    'Administrator Kampus',
    'admin@sakuskill.ac.id',
    '$2a$10$5k4Vf9s8Z/IVSud66lG7teZTwjWe5htI8fHFATpxgxKIOXCWuFj1K',
    'Administrator',
    'Terverifikasi',
    'Administrator Operasional & Mediasi SakuSkill UIN Sunan Gunung Djati Bandung.',
    'Aktif'
)
ON CONFLICT (email) DO NOTHING;

COMMIT;
