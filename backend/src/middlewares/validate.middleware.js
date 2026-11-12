const AppError = require('../utils/AppError');

const validateRequest = (schema) => (req, res, next) => {
  const result = schema.safeParse({
    body: req.body,
    query: req.query,
    params: req.params,
  });

  if (!result.success) {
    const formattedErrors = result.error.issues.map((issue) => ({
      field: issue.path.join('.'),
      message: issue.message,
    }));
    return next(
      new AppError(
        'Data masukan tidak valid. Periksa kembali kolom yang wajib diisi.',
        422,
        'VALIDATION_ERROR',
        formattedErrors
      )
    );
  }

  req.validated = result.data;
  return next();
};

module.exports = validateRequest;
