'use strict';

const { Pool } = require('pg');
const logger = require('./logger');

// Connection settings are injected via environment variables. In Azure these
// come from Key Vault (via the Secrets Store CSI driver) and a ConfigMap.
const useSsl = String(process.env.PGSSLMODE || 'require').toLowerCase() !== 'disable';

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: Number(process.env.PGPORT || 5432),
  user: process.env.PGUSER || 'appuser',
  password: process.env.PGPASSWORD || 'appsecret',
  database: process.env.PGDATABASE || 'appdb',
  max: Number(process.env.PG_POOL_MAX || 10),
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  // Azure Database for PostgreSQL requires TLS by default.
  ssl: useSsl ? { rejectUnauthorized: false } : false
});

pool.on('error', (err) => {
  logger.error({ err }, 'unexpected error on idle postgres client');
});

async function query(text, params) {
  return pool.query(text, params);
}

async function healthCheck() {
  const res = await pool.query('SELECT 1 AS ok');
  return res.rows[0].ok === 1;
}

module.exports = { pool, query, healthCheck };
