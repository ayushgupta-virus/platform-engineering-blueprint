module.exports = {
  testEnvironment: 'node',
  // server.js and migrate.js are process entry points exercised by the
  // container / init-container, not by the unit suite.
  collectCoverageFrom: ['src/**/*.js', '!src/server.js', '!src/migrate.js'],
  coverageThreshold: {
    global: {
      branches: 35,
      functions: 50,
      lines: 55,
      statements: 55
    }
  }
};
