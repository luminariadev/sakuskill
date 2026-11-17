const { z } = require('zod');

const targetTipeEnum = z.enum(['Pengguna', 'Listing', 'Ulasan', 'Pesan', 'Pesanan', 'Barter'], {
  errorMap: () => ({
    message: "target_tipe harus bernilai 'Pengguna', 'Listing', 'Ulasan', 'Pesan', 'Pesanan', atau 'Barter'.",
  }),
});

const reportStatusEnum = z.enum(['Baru', 'Ditinjau', 'Selesai'], {
  errorMap: () => ({
    message: "status_penanganan harus bernilai 'Baru', 'Ditinjau', atau 'Selesai'.",
  }),
});

const createReportSchema = z.object({
  body: z.object({
    target_tipe: targetTipeEnum,
    target_id: z.string({ required_error: 'target_id wajib diisi.' }).uuid('target_id harus berupa UUID.'),
    alasan: z.string({ required_error: 'alasan komplain wajib diisi.' }).trim().min(3).max(255),
    keterangan: z.string({ required_error: 'keterangan komplain wajib diisi.' }).trim().min(5).max(3000),
  }),
});

const reportIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID report harus berupa UUID valid.'),
  }),
});

const updateReportStatusSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID report harus berupa UUID valid.'),
  }),
  body: z.object({
    status_penanganan: reportStatusEnum,
    keputusan: z.string().trim().max(3000).optional(),
  }),
});

module.exports = {
  createReportSchema,
  reportIdParamSchema,
  updateReportStatusSchema,
};
