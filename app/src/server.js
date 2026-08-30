'use strict';

const { createApp } = require('./app');
const logger = require('./logger');
const { pool } = require('./db');

const port = Number(process.env.PORT || 3000);
const app = createApp();

const server = app.listen(port, () => {
  logger.info({ port }, 'todo-api listening');
});

// Graceful shutdown so Kubernetes rolling updates drain connections cleanly.
function shutdown(signal) {
  logger.info({ signal }, 'shutting down');
  server.close(async () => {
    try {
      await pool.end();
    } catch (err) {
      logger.error({ err }, 'error closing pg pool');
    }
    process.exit(0);
  });
  // Force-exit if graceful shutdown stalls.
  setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = server;
