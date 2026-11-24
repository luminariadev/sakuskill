const fs = require('fs');
const path = require('path');

const isServerless = Boolean(process.env.VERCEL || process.env.AWS_LAMBDA_FUNCTION_NAME);
const logsDir = path.resolve(__dirname, '../../logs');
const requestLogFile = path.join(logsDir, 'backend-requests.log');
let fileLoggingEnabled = !isServerless;

if (fileLoggingEnabled) {
  try {
    fs.mkdirSync(logsDir, { recursive: true });
  } catch (_) {
    fileLoggingEnabled = false;
  }
}

/**
 * Mencatat setiap HTTP request ke stdout dan (pada environment non-serverless)
 * ke file `backend/logs/backend-requests.log` lengkap dengan IP klien, user ID JWT, dan User-Agent.
 */
const requestLogger = (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const durationMs = Date.now() - start;
    const timestamp = new Date().toISOString();
    const forwardedFor = req.headers['x-forwarded-for'];
    const firstForwarded = typeof forwardedFor === 'string'
      ? forwardedFor.split(',')[0].trim()
      : null;
    const clientIp = req.headers['cf-connecting-ip'] || firstForwarded || req.ip || '-';
    const userId = (req.user && (req.user.user_id || req.user.id)) || 'anon';
    const userAgent = String(req.headers['user-agent'] || '-').replace(/"/g, "'");
    const line = `[${timestamp}] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${durationMs}ms) | ip=${clientIp} | user=${userId} | ua="${userAgent}"`;
    console.log(line);
    if (fileLoggingEnabled) {
      try {
        fs.appendFileSync(requestLogFile, `${line}\n`, 'utf8');
      } catch (_) {
        // Jangan gagalkan respons HTTP jika disk log bermasalah
      }
    }
  });
  next();
};

module.exports = requestLogger;
