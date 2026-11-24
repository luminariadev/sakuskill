const fs = require('fs');
const path = require('path');

const logsDir = path.resolve(__dirname, '../../logs');
const requestLogFile = path.join(logsDir, 'backend-requests.log');
fs.mkdirSync(logsDir, { recursive: true });

/**
 * Mencatat setiap HTTP request ke stdout dan file `backend/logs/backend-requests.log`
 * lengkap dengan IP klien (dari Cloudflare/proxy atau lokal), user ID JWT, dan User-Agent.
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
    try {
      fs.appendFileSync(requestLogFile, `${line}\n`, 'utf8');
    } catch (_) {
      // Jangan gagalkan respons HTTP jika disk log bermasalah
    }
  });
  next();
};

module.exports = requestLogger;
