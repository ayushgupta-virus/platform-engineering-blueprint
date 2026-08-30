'use strict';

const pino = require('pino');

// Structured JSON logs go to stdout so the container runtime / Azure Monitor
// Container Insights can collect them as centralized application logs.
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: {
    service: 'todo-api',
    env: process.env.APP_ENV || 'local'
  },
  formatters: {
    level(label) {
      return { level: label };
    }
  },
  timestamp: pino.stdTimeFunctions.isoTime
});

module.exports = logger;
