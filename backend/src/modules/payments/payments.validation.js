const { z } = require('zod');
const AppError = require('../../utils/AppError');

const FORBIDDEN_STATUS_FIELDS = [
  'status',
  'status_kode',
  'status_pembayaran',
  'status_pembayaran_kode',
  'payment_status',
  'state',
];

/**
 * Middleware Kerjaan #5 & Acceptance Criteria:
 * Backend yang menetapkan status; tolak tegas jika client mengirim field status pada payload.
 */
function rejectClientStatusOverride(req, res, next) {
  if (req.body && typeof req.body === 'object') {
    const injected = FORBIDDEN_STATUS_FIELDS.filter((key) => key in req.body);
    if (injected.length > 0) {
      return next(
        new AppError(
          `Client dilarang menetapkan atau memaksa status pembayaran (${injected.join(", ")}). Status pembayaran ditetapkan sepenuhnya oleh backend.`,
          400,
          'CLIENT_CANNOT_FORCE_STATUS'
        )
      );
    }
  }
  return next();
}

/**
 * Middleware Kerjaan #3:
 * Endpoint simulasi hanya aktif untuk environment demo/development/test atau dibatasi secara aman.
 */
function requireSimulationEnv(req, res, next) {
  const envMode = String(process.env.NODE_ENV || 'development').toLowerCase();
  const allowedEnvs = ['development', 'demo', 'test', 'local'];
  const explicitFlag = String(process.env.ENABLE_PAYMENT_SIMULATION || 'true').toLowerCase() === 'true';

  if (envMode === 'production' && !explicitFlag) {
    return next(
      new AppError(
        'Endpoint simulasi pembayaran dinonaktifkan pada environment production.',
        403,
        'SIMULATION_DISABLED_IN_PRODUCTION'
      )
    );
  }
  if (!allowedEnvs.includes(envMode) && !explicitFlag) {
    return next(
      new AppError(
        `Simulasi pembayaran hanya diizinkan pada environment demo/development (saat ini: ${envMode}).`,
        403,
        'SIMULATION_ENV_RESTRICTED'
      )
    );
  }
  return next();
}

const createPaymentSchema = z.object({
  body: z.object({
    order_id: z.string({ required_error: 'order_id wajib diisi.' }).uuid('Format order_id harus berupa UUID.'),
    metode_simulasi: z
      .string()
      .trim()
      .max(50)
      .optional()
      .default('SIMULASI_MVP'),
    catatan: z.string().trim().max(500).optional(),
  }),
});

const orderIdParamSchema = z.object({
  params: z.object({
    orderId: z.string().uuid('Format orderId harus berupa UUID yang valid.'),
  }),
});

const simulateActionSchema = z.object({
  params: z.object({
    orderId: z.string().uuid('Format orderId harus berupa UUID yang valid.'),
  }),
  body: z
    .object({
      catatan: z.string().trim().max(500).optional(),
      alasan_gagal: z.string().trim().max(500).optional(),
    })
    .optional()
    .default({}),
});

module.exports = {
  rejectClientStatusOverride,
  requireSimulationEnv,
  createPaymentSchema,
  orderIdParamSchema,
  simulateActionSchema,
};