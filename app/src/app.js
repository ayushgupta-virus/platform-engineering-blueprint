'use strict';

const path = require('path');
const express = require('express');
const pinoHttp = require('pino-http');

const logger = require('./logger');
const db = require('./db');
const { register, metricsMiddleware } = require('./metrics');
const todosRouter = require('./routes/todos');

function createApp() {
  const app = express();

  app.disable('x-powered-by');
  app.use(express.json());

  // Access logging (structured) -> stdout -> Container Insights.
  app.use(pinoHttp({ logger }));

  // Prometheus request metrics.
  app.use(metricsMiddleware);

  // Liveness probe: process is up.
  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  // Readiness probe: dependencies (database) are reachable.
  app.get('/ready', async (req, res) => {
    try {
      await db.healthCheck();
      res.json({ status: 'ready' });
    } catch (err) {
      logger.warn({ err }, 'readiness check failed');
      res.status(503).json({ status: 'not-ready' });
    }
  });

  // Prometheus scrape endpoint.
  app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  });

  app.use('/todos', todosRouter);

  // Static frontend.
  app.use('/', express.static(path.join(__dirname, '..', 'public')));

  // Centralized error handler -> increments error-rate metrics via status code.
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    logger.error({ err }, 'unhandled request error');
    res.status(500).json({ error: 'internal server error' });
  });

  return app;
}

module.exports = { createApp };
