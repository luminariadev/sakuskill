const { z } = require('zod');

const createOrderSchema = z.object({
  body: z.object({
    listing_id: z.string({ required_error: 'listing_id wajib diisi.' }).uuid('Format listing_id harus berupa UUID.'),
    ruang_lingkup: z
      .string()
      .trim()
      .min(10, 'Kesepakatan ruang lingkup (scope) minimal 10 karakter.')
      .max(3000, 'Ruang lingkup maksimal 3000 karakter.')
      .optional(),
    catatan_kebutuhan: z
      .string()
      .trim()
      .min(10, 'Catatan kebutuhan / scope minimal 10 karakter.')
      .max(3000)
      .optional(),
    harga_kesepakatan: z.coerce
      .number()
      .min(0, 'Harga kesepakatan tidak boleh negatif.')
      .max(100000000)
      .optional(),
    tenggat_pekerjaan: z
      .string({ required_error: 'tenggat_pekerjaan (deadline) wajib diisi (format ISO-8601 / YYYY-MM-DD).' })
      .refine((val) => !Number.isNaN(Date.parse(val)), {
        message: 'Format tenggat_pekerjaan (deadline) tidak valid.',
      }),
  }).refine((data) => Boolean(data.ruang_lingkup || data.catatan_kebutuhan), {
    message: 'Wajib mengisi ruang_lingkup (scope) atau catatan_kebutuhan pekerjaan.',
    path: ['ruang_lingkup'],
  }),
});

const orderIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
});

const createProposalSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    deskripsi_ruang_lingkup: z
      .string({ required_error: 'deskripsi_ruang_lingkup (scope) wajib diisi.' })
      .trim()
      .min(10, 'Deskripsi ruang lingkup minimal 10 karakter.')
      .max(3000),
    harga_tawaran: z.coerce
      .number({ required_error: 'harga_tawaran wajib diisi.' })
      .min(0, 'Harga tawaran tidak boleh negatif.'),
    tenggat_usulan: z
      .string()
      .refine((val) => !Number.isNaN(Date.parse(val)), {
        message: 'Format tenggat_usulan tidak valid.',
      })
      .optional(),
  }),
});

const acceptOrderSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    ruang_lingkup: z.string().trim().min(10).max(3000).optional(),
    harga_kesepakatan: z.coerce.number().min(0).optional(),
    tenggat_pekerjaan: z
      .string()
      .refine((val) => !Number.isNaN(Date.parse(val)), {
        message: 'Format tenggat_pekerjaan tidak valid.',
      })
      .optional(),
  }).optional().default({}),
});

const reasonBodySchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    alasan: z.string().trim().min(3).max(1000).optional(),
  }).optional().default({}),
});

const updateOrderStatusSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    status: z.string({ required_error: 'Target status wajib diisi.' }).trim(),
    alasan: z.string().trim().max(1000).optional(),
    ruang_lingkup: z.string().trim().min(10).max(3000).optional(),
    harga_kesepakatan: z.coerce.number().min(0).optional(),
    tenggat_pekerjaan: z.string().optional(),
  }),
});

const createOrderReviewSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    rating: z.coerce
      .number({ required_error: 'Rating wajib diisi.' })
      .int()
      .min(1, 'Rating minimal 1.')
      .max(5, 'Rating maksimal 5.'),
    rating_kualitas: z.coerce.number().int().min(1).max(5).optional(),
    rating_ketepatan_waktu: z.coerce.number().int().min(1).max(5).optional(),
    komentar: z.string().trim().min(3, 'Komentar ulasan minimal 3 karakter.').max(2000).optional(),
  }),
});

const createOrderMessageSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    isi_pesan: z
      .string({ required_error: 'isi_pesan wajib diisi.' })
      .trim()
      .min(1, 'Pesan tidak boleh kosong.')
      .max(2000, 'Pesan maksimal 2000 karakter.'),
  }),
});

const requestTimeExtensionSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    tambahan_jam: z.coerce
      .number({ required_error: 'tambahan_jam wajib diisi.' })
      .int()
      .min(1, 'Tambahan waktu minimal 1 jam.')
      .max(168, 'Tambahan waktu maksimal 168 jam (7 hari).'),
    alasan: z
      .string({ required_error: 'Alasan permintaan tambahan waktu wajib diisi.' })
      .trim()
      .min(5, 'Alasan minimal 5 karakter.')
      .max(1000, 'Alasan maksimal 1000 karakter.'),
  }),
});

const decideTimeExtensionSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID order harus berupa UUID yang valid.'),
  }),
  body: z.object({
    disetujui: z.boolean({ required_error: 'Field disetujui (true/false) wajib diisi.' }),
  }),
});

module.exports = {
  createOrderSchema,
  orderIdParamSchema,
  createProposalSchema,
  acceptOrderSchema,
  reasonBodySchema,
  updateOrderStatusSchema,
  createOrderReviewSchema,
  createOrderMessageSchema,
  requestTimeExtensionSchema,
  decideTimeExtensionSchema,
};