'use strict';

// Unit tests exercise the HTTP layer with the database module mocked out,
// so they run fast and need no external services (suitable for PR checks).
jest.mock('../../src/db', () => ({
  query: jest.fn(),
  healthCheck: jest.fn(),
  pool: { end: jest.fn() }
}));

const request = require('supertest');
const db = require('../../src/db');
const { createApp } = require('../../src/app');

const app = createApp();

beforeEach(() => {
  jest.clearAllMocks();
});

describe('health & metrics', () => {
  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  test('GET /ready returns ready when db is reachable', async () => {
    db.healthCheck.mockResolvedValue(true);
    const res = await request(app).get('/ready');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ready');
  });

  test('GET /ready returns 503 when db is down', async () => {
    db.healthCheck.mockRejectedValue(new Error('connection refused'));
    const res = await request(app).get('/ready');
    expect(res.status).toBe(503);
  });

  test('GET /metrics exposes prometheus metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.status).toBe(200);
    expect(res.text).toContain('http_requests_total');
  });
});

describe('todos API (mocked db)', () => {
  test('GET /todos returns list', async () => {
    db.query.mockResolvedValue({ rows: [{ id: 1, title: 'a', completed: false }] });
    const res = await request(app).get('/todos');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
  });

  test('POST /todos validates empty title', async () => {
    const res = await request(app).post('/todos').send({ title: '   ' });
    expect(res.status).toBe(400);
    expect(db.query).not.toHaveBeenCalled();
  });

  test('POST /todos creates a todo', async () => {
    db.query.mockResolvedValue({ rows: [{ id: 2, title: 'buy milk', completed: false }] });
    const res = await request(app).post('/todos').send({ title: 'buy milk' });
    expect(res.status).toBe(201);
    expect(res.body.title).toBe('buy milk');
  });

  test('GET /todos/:id returns 404 when missing', async () => {
    db.query.mockResolvedValue({ rows: [] });
    const res = await request(app).get('/todos/999');
    expect(res.status).toBe(404);
  });
});
