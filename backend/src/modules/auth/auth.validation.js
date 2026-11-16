const { z } = require('zod');

const registerSchema = z.object({
  body: z.object({
    nama: z
      .string({ required_error: 'Nama wajib diisi.' })
      .trim()
      .min(2, 'Nama minimal 2 karakter.')
      .max(150, 'Nama maksimal 150 karakter.'),
    email: z
      .string({ required_error: 'Email wajib diisi.' })
      .trim()
      .email('Format alamat email tidak valid.')
      .max(255, 'Email maksimal 255 karakter.')
      .transform((val) => val.toLowerCase()),
    kata_sandi: z
      .string({ required_error: 'Kata sandi wajib diisi.' })
      .min(8, 'Kata sandi minimal 8 karakter.')
      .max(100, 'Kata sandi maksimal 100 karakter.'),
    deskripsi_profil: z
      .string()
      .trim()
      .max(1000, 'Deskripsi profil maksimal 1000 karakter.')
      .optional()
      .nullable(),
    peran: z.enum(['Pelanggan', 'Penyedia Jasa']).optional(),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z
      .string({ required_error: 'Email wajib diisi.' })
      .trim()
      .email('Format alamat email tidak valid.')
      .transform((val) => val.toLowerCase()),
    kata_sandi: z
      .string({ required_error: 'Kata sandi wajib diisi.' })
      .min(1, 'Kata sandi wajib diisi.'),
  }),
});

module.exports = {
  registerSchema,
  loginSchema,
};
