const { z } = require('zod');

const getHyperlocalListingsSchema = z.object({
  query: z.object({
    lat: z.coerce.number().min(-90).max(90).optional(),
    lng: z.coerce.number().min(-180).max(180).optional(),
    radius_m: z.coerce.number().int().min(100).max(10000).optional(),
    tipe_penawaran: z.enum(['Berbayar', 'Barter', 'Berbayar dan Barter']).optional(),
  }),
});

module.exports = { getHyperlocalListingsSchema };
