'use strict';

// Minimal SQL migration runner. Applies every .sql file in ./migrations in
// lexical order inside a transaction. Idempotent statements keep it re-runnable.
const fs = require('fs');
const path = require('path');
const db = require('./db');
const logger = require('./logger');

async function run() {
  const dir = path.join(__dirname, '..', 'migrations');
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), 'utf8');
    logger.info({ file }, 'applying migration');
    await db.query(sql);
  }
  logger.info('migrations complete');
  await db.pool.end();
}

run().catch((err) => {
  logger.error({ err }, 'migration failed');
  process.exit(1);
});
