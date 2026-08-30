'use strict';

const client = require('prom-client');

// Default process/runtime metrics (CPU, memory, event loop lag, GC, ...).
const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'app_' });

// Core application metrics: request rate, error rate, latency.
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);

// Express middleware that records duration + count for every request.
function metricsMiddleware(req, res, next) {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    // Use the matched route path (e.g. /todos/:id) to keep cardinality low.
    const route = req.route ? req.baseUrl + req.route.path : req.path;
    const labels = {
      method: req.method,
      route,
      status_code: res.statusCode
    };
    end(labels);
    httpRequestsTotal.inc(labels);
  });
  next();
}

module.exports = { register, metricsMiddleware, httpRequestDuration, httpRequestsTotal };
