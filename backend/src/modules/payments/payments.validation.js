const { z } = require('zod');

const ALLOWED_METHODS = [
  'QRIS',
  'GOPAY',
  'SHOPEEPAY',
  'BCA_VA',
  'BNI_VA',
  'BRI_VA',
  'MANDIRI_BILL',
];

const checkoutPaymentSchema = z.object({
  body: z.object({
    order_id: z.string({ required_error: 'order_id wajib diisi.' }).uuid('Format order_id harus berupa UUID.'),
    metode_pembayaran: z
      .string()
      .trim()
      .toUpperCase()
      .refine((val) => ALLOWED_METHODS.includes(val), {
        message: `Metode pembayaran harus salah satu dari: ${ALLOWED_METHODS.join(", ")}`,
      })
      .default('QRIS'),
  }),
});

const orderIdParamSchema = z.object({
  params: z.object({
    orderId: z.string().uuid('Format orderId harus berupa UUID yang valid.'),
  }),
});

const webhookNotificationSchema = z.object({
  body: z.object({
    order_id: z.string({ required_error: 'order_id (referensi_gateway atau UUID order) wajib diisi.' }).trim(),
    transaction_status: z.enum(['capture', 'settlement', 'pending', 'deny', 'cancel', 'expire', 'failure', 'refund']),
    status_code: z.string().default('200'),
    gross_amount: z.union([z.string(), z.number()]),
    signature_key: z.string().optional(),
    payment_type: z.string().optional(),
  }),
});

const escrowActionSchema = z.object({
  params: z.object({
    orderId: z.string().uuid('Format orderId harus berupa UUID yang valid.'),
  }),
  body: z
    .object({
      catatan: z.string().trim().max(1000).optional(),
      alasan: z.string().trim().max(1000).optional(),
    })
    .optional()
    .default({}),
});

module.exports = {
  checkoutPaymentSchema,
  orderIdParamSchema,
  webhookNotificationSchema,
  escrowActionSchema,
};