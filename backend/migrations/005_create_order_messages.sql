BEGIN;

CREATE TABLE IF NOT EXISTS order_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    isi_pesan TEXT NOT NULL CHECK (char_length(trim(isi_pesan)) > 0),
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_messages_order_id ON order_messages(order_id, dibuat_pada ASC);

COMMIT;