BEGIN;

-- Tabel untuk menyimpan token JWT yang dicabut saat logout (FR-06 & Kerjaan #1)
CREATE TABLE IF NOT EXISTS revoked_tokens (
    jti VARCHAR(100) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires_at ON revoked_tokens (expires_at);
CREATE INDEX IF NOT EXISTS idx_service_listings_penyedia ON service_listings (penyedia_id);
CREATE INDEX IF NOT EXISTS idx_service_listings_skill ON service_listings (skill_id);

-- Tambah kategori umum tambahan sesuai kebutuhan kampus (FR-23)
INSERT INTO skills (nama_keterampilan, kategori) VALUES
    ('Penulisan & Proofreading Dokumen', 'Akademik & Dokumen'),
    ('Editing Video & Motion Graphics', 'Desain'),
    ('Perbaikan Hardware & Jaringan Kos', 'Jasa Teknis')
ON CONFLICT (nama_keterampilan) DO NOTHING;

COMMIT;
