const { z } = require('zod');

const createBarterSchema = z.object({
  body: z.object({
    listing_id: z.string({ required_error: 'listing_id (jasa sasaran) wajib diisi.' }).uuid('Format listing_id harus berupa UUID.'),
    listing_pengaju_id: z.string().uuid().optional().nullable(),
    penerima_id: z.string().uuid().optional(),
    deskripsi_jasa_pengaju: z
      .string({ required_error: 'deskripsi_jasa_pengaju wajib diisi.' })
      .trim()
      .min(10, 'Deskripsi pekerjaan pengaju minimal 10 karakter.')
      .max(3000),
    deskripsi_jasa_penerima: z
      .string({ required_error: 'deskripsi_jasa_penerima wajib diisi.' })
      .trim()
      .min(10, 'Deskripsi pekerjaan penerima minimal 10 karakter.')
      .max(3000),
    tenggat_pekerjaan: z
      .string({ required_error: 'tenggat_pekerjaan (deadline) barter wajib diisi.' })
      .refine((val) => !Number.isNaN(Date.parse(val)), {
        message: 'Format tenggat_pekerjaan tidak valid.',
      }),
  }),
});

const barterIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID barter harus berupa UUID yang valid.'),
  }),
});

const updateBarterTermsSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID barter harus berupa UUID yang valid.'),
  }),
  body: z.object({
    deskripsi_jasa_pengaju: z.string().trim().min(10).max(3000).optional(),
    deskripsi_jasa_penerima: z.string().trim().min(10).max(3000).optional(),
    tenggat_pekerjaan: z
      .string()
      .refine((val) => !Number.isNaN(Date.parse(val)), {
        message: 'Format tenggat_pekerjaan tidak valid.',
      })
      .optional(),
  }).refine((b) => Object.keys(b).length > 0, {
    message: 'Minimal satu field deskripsi pekerjaan atau tenggat harus dikirim.',
  }),
});

const confirmBarterCompletionSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID barter harus berupa UUID yang valid.'),
  }),
  body: z.object({
    catatan: z.string().trim().max(1000).optional(),
  }).optional().default({}),
});

const barterReasonSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID barter harus berupa UUID yang valid.'),
  }),
  body: z.object({
    alasan: z.string().trim().max(1000).optional(),
  }).optional().default({}),
});

const updateBarterStatusSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID barter harus berupa UUID yang valid.'),
  }),
  body: z.object({
    status: z.string({ required_error: 'Target status wajib diisi.' }).trim(),
    alasan: z.string().trim().max(1000).optional(),
    catatan: z.string().trim().max(1000).optional(),
  }),
});

const createBarterReviewSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID barter harus berupa UUID yang valid.'),
  }),
  body: z.object({
    rating: z.coerce.number().int().min(1).max(5),
    rating_kualitas: z.coerce.number().int().min(1).max(5).optional(),
    rating_ketepatan_waktu: z.coerce.number().int().min(1).max(5).optional(),
    komentar: z.string().trim().min(3).max(2000).optional(),
  }),
});

module.exports = {
  createBarterSchema,
  barterIdParamSchema,
  updateBarterTermsSchema,
  confirmBarterCompletionSchema,
  barterReasonSchema,
  updateBarterStatusSchema,
  createBarterReviewSchema,
};