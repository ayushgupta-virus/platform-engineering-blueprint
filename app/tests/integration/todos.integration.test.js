'use strict';

// Integration tests run against a real PostgreSQL instance (provided by the CI
// service container or a local docker postgres). They verify the SQL, schema,
// and HTTP layers work together end to end.
const fs = require('fs');
const path = require('path');
const request = require('supertest');
const db = require('../../src/db');
const { createApp } = require('../../src/app');

const app = createApp();

beforeAll(async () => {
  const schema = fs.readFileSync(
    path.join(__dirname, '..', '..', 'migrations', '001_init.sql'),
    'utf8'
  );
  await db.query(schema);
  await db.query('TRUNCATE todos RESTART IDENTITY');
});

afterAll(async () => {
  await db.pool.end();
});

describe('todos API (real database)', () => {
  let createdId;

  test('creates a todo', async () => {
    const res = await request(app).post('/todos').send({ title: 'integration item' });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    createdId = res.body.id;
  });

  test('lists the created todo', async () => {
    const res = await request(app).get('/todos');
    expect(res.status).toBe(200);
    expect(res.body.some((t) => t.id === createdId)).toBe(true);
  });

  test('marks the todo complete', async () => {
    const res = await request(app).patch(`/todos/${createdId}`).send({ completed: true });
    expect(res.status).toBe(200);
    expect(res.body.completed).toBe(true);
  });

  test('deletes the todo', async () => {
    const res = await request(app).delete(`/todos/${createdId}`);
    expect(res.status).toBe(204);
  });

  test('readiness passes against the real database', async () => {
    const res = await request(app).get('/ready');
    expect(res.status).toBe(200);
  });
});
