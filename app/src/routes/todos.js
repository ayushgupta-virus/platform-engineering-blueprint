'use strict';

const express = require('express');
const db = require('../db');

const router = express.Router();

// Basic input validation kept intentionally small.
function validateTodo(body) {
  if (!body || typeof body.title !== 'string' || body.title.trim().length === 0) {
    return 'title is required and must be a non-empty string';
  }
  if (body.title.length > 255) {
    return 'title must be 255 characters or fewer';
  }
  return null;
}

// List todos
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT id, title, completed, created_at FROM todos ORDER BY created_at DESC LIMIT 100'
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

// Get a single todo
router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT id, title, completed, created_at FROM todos WHERE id = $1',
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'todo not found' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});

// Create a todo
router.post('/', async (req, res, next) => {
  const validationError = validateTodo(req.body);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }
  try {
    const { rows } = await db.query(
      'INSERT INTO todos (title, completed) VALUES ($1, $2) RETURNING id, title, completed, created_at',
      [req.body.title.trim(), Boolean(req.body.completed)]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
});

// Update completion state
router.patch('/:id', async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'UPDATE todos SET completed = $1 WHERE id = $2 RETURNING id, title, completed, created_at',
      [Boolean(req.body.completed), req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'todo not found' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});

// Delete a todo
router.delete('/:id', async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM todos WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'todo not found' });
    }
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
