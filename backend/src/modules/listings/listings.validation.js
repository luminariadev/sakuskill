const { z } = require('zod');

const offerTypeEnum = z.enum(['Berbayar', 'Barter', 'Berbayar dan Barter'], {
  errorMap: () => ({
    message: "tipe_penawaran harus bernilai 'Berbayar', 'Barter', atau 'Berbayar dan Barter'.",
  }),
});

const publicationStatusEnum = z.enum(['Aktif', 'Nonaktif'], {
  errorMap: () => ({
    message: "status publikasi harus bernilai 'Aktif' atau 'Nonaktif'.",
  }),
});

const createGigSchema = z.object({
  body: z
    .object({
      judul: z
        .string({ required_error: 'Judul gig/listing wajib diisi.' })
        .trim()
        .min(5, 'Judul minimal 5 karakter.')
        .max(200, 'Judul maksimal 200 karakter.'),
      deskripsi: z
        .string({ required_error: 'Deskripsi wajib diisi.' })
        .trim()
        .min(20, 'Deskripsi minimal 20 karakter agar jelas bagi pelanggan.')
        .max(5000, 'Deskripsi maksimal 5000 karakter.'),
      skill_id: z.coerce
        .number({ invalid_type_error: 'skill_id harus berupa angka.' })
        .int()
        .positive('skill_id wajib berupa ID keterampilan yang valid.')
        .optional(),
      kategori: z.string().trim().min(2).max(100).optional(),
      harga: z.coerce
        .number({ required_error: 'Harga wajib diisi (isi 0 untuk murni Barter).' })
        .min(0, 'Harga tidak boleh bernilai negatif (minimal 0).')
        .max(100000000, 'Harga melebihi batas maksimum transaksi mikro.'),
      latitude: z.coerce
        .number({ required_error: 'Koordinat latitude lokasi wajib diisi.' })
        .min(-90, 'Latitude minimal -90.')
        .max(90, 'Latitude maksimal 90.'),
      longitude: z.coerce
        .number({ required_error: 'Koordinat longitude lokasi wajib diisi.' })
        .min(-180, 'Longitude minimal -180.')
        .max(180, 'Longitude maksimal 180.'),
      tipe_penawaran: offerTypeEnum.default('Berbayar'),
      deskripsi_imbalan_barter: z
        .string()
        .trim()
        .max(1000, 'Deskripsi imbalan barter maksimal 1000 karakter.')
        .optional()
        .nullable(),
      status: publicationStatusEnum.default('Aktif'),
    })
    .refine((data) => data.skill_id !== undefined || data.kategori !== undefined, {
      message: 'Wajib menyertakan skill_id atau nama kategori layanan.',
      path: ['skill_id'],
    })
    .refine(
      (data) => {
        if (data.tipe_penawaran === 'Barter' || data.tipe_penawaran === 'Berbayar dan Barter') {
          return (
            typeof data.deskripsi_imbalan_barter === 'string' &&
            data.deskripsi_imbalan_barter.trim().length >= 5
          );
        }
        return true;
      },
      {
        message:
          'Untuk penawaran Barter, deskripsi_imbalan_barter wajib diisi (minimal 5 karakter).',
        path: ['deskripsi_imbalan_barter'],
      }
    ),
});

const updateGigSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID gig/listing harus berupa UUID yang valid.'),
  }),
  body: z
    .object({
      judul: z
        .string()
        .trim()
        .min(5, 'Judul minimal 5 karakter.')
        .max(200, 'Judul maksimal 200 karakter.')
        .optional(),
      deskripsi: z
        .string()
        .trim()
        .min(20, 'Deskripsi minimal 20 karakter.')
        .max(5000, 'Deskripsi maksimal 5000 karakter.')
        .optional(),
      skill_id: z.coerce.number().int().positive().optional(),
      kategori: z.string().trim().min(2).max(100).optional(),
      harga: z.coerce
        .number()
        .min(0, 'Harga tidak boleh bernilai negatif.')
        .max(100000000, 'Harga melebihi batas maksimum.')
        .optional(),
      latitude: z.coerce.number().min(-90).max(90).optional(),
      longitude: z.coerce.number().min(-180).max(180).optional(),
      tipe_penawaran: offerTypeEnum.optional(),
      deskripsi_imbalan_barter: z.string().trim().max(1000).nullable().optional(),
      status: publicationStatusEnum.optional(),
    })
    .refine((body) => Object.keys(body).length > 0, {
      message: 'Minimal satu field harus dikirim untuk memperbarui gig.',
    }),
});

const updateGigStatusSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID gig/listing harus berupa UUID yang valid.'),
  }),
  body: z.object({
    status: publicationStatusEnum,
  }),
});

const gigIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID gig/listing harus berupa UUID yang valid.'),
  }),
});

const discoveryQuerySchema = z.object({
  query: z.object({
    q: z.string().trim().max(150).optional(),
    search: z.string().trim().max(150).optional(),
    kategori: z.string().trim().max(100).optional(),
    skill_id: z.coerce.number().int().positive().optional(),
    tipe_penawaran: offerTypeEnum.optional(),
    min_harga: z.coerce.number().min(0).optional(),
    max_harga: z.coerce.number().min(0).optional(),
    min_rating: z.coerce.number().min(0).max(5).optional(),
    penyedia_id: z.string().uuid().optional(),
    lat: z.coerce.number().min(-90).max(90).optional(),
    lng: z.coerce.number().min(-180).max(180).optional(),
    radius_m: z.coerce.number().int().min(100).max(50000).optional(),
    use_radius: z
      .enum(['true', 'false'])
      .optional()
      .transform((val) => val !== 'false'),
    sort_by: z
      .enum(['jarak', 'harga_asc', 'harga_desc', 'rating', 'terbaru'])
      .optional()
      .default('jarak'),
    page: z.coerce.number().int().min(1).optional().default(1),
    limit: z.coerce.number().int().min(1).max(100).optional().default(20),
  }),
});

const moderateGigSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID gig/listing harus berupa UUID yang valid.'),
  }),
  body: z.object({
    status: z.enum(['Aktif', 'Nonaktif', 'Disembunyikan Moderasi']),
    alasan: z.string().trim().min(5, 'Alasan moderasi minimal 5 karakter.').max(500),
  }),
});

module.exports = {
  createGigSchema,
  updateGigSchema,
  updateGigStatusSchema,
  gigIdParamSchema,
  discoveryQuerySchema,
  moderateGigSchema,
};
