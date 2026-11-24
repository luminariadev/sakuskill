const { z } = require('zod');

const updateProfileSchema = z.object({
  body: z
    .object({
      nama: z
        .string()
        .trim()
        .min(2, 'Nama minimal 2 karakter.')
        .max(150, 'Nama maksimal 150 karakter.')
        .optional(),
      deskripsi_profil: z
        .string()
        .trim()
        .max(1000, 'Deskripsi profil maksimal 1000 karakter.')
        .nullable()
        .optional(),
      foto_profil: z
        .string()
        .trim()
        .max(500000, 'Ukuran foto profil terlalu besar (maks. ~350KB).')
        .refine(
          (v) => v === '' || v.startsWith('data:image/') || v.startsWith('https://'),
          { message: 'Format foto profil harus berupa gambar valid atau URL https.' }
        )
        .nullable()
        .optional(),
      skill_ids: z
        .array(z.coerce.number().int().positive())
        .max(20, 'Maksimal memilih 20 keterampilan.')
        .optional(),
    })
    .refine(
      (data) =>
        data.nama !== undefined ||
        data.deskripsi_profil !== undefined ||
        data.foto_profil !== undefined ||
        data.skill_ids !== undefined,
      {
        message: 'Minimal satu field (nama, deskripsi_profil, foto_profil, atau skill_ids) harus dikirim untuk diperbarui.',
      }
    ),
});

const userIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID pengguna harus berupa UUID yang valid.'),
  }),
});

const verifyUserSchema = z.object({
  params: z.object({
    id: z.string().uuid('Format ID pengguna harus berupa UUID yang valid.'),
  }),
  body: z.object({
    status_verifikasi: z.enum(['Belum Terverifikasi', 'Terverifikasi', 'Ditolak'], {
      required_error: 'status_verifikasi wajib diisi.',
    }),
  }),
});

module.exports = {
  updateProfileSchema,
  userIdParamSchema,
  verifyUserSchema,
};
