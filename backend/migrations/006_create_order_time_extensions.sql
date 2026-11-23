CREATE TABLE IF NOT EXISTS order_time_extensions (
  extension_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  pengaju_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  tambahan_jam INTEGER NOT NULL CHECK (tambahan_jam > 0),
  alasan TEXT NOT NULL,
  status_persetujuan VARCHAR(30) NOT NULL DEFAULT 'pending',
  dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  diputuskan_pada TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_order_time_extensions_order_id
  ON order_time_extensions(order_id, dibuat_pada DESC);