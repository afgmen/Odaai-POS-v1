'use strict';

const levels = { error: 0, warn: 1, info: 2, debug: 3 };
const currentLevel = process.env.NODE_ENV === 'production' ? 'info' : 'debug';

function log(level, message, meta) {
  if (levels[level] > levels[currentLevel]) return;

  const ts = new Date().toISOString();
  const prefix = `[${ts}] [${level.toUpperCase()}]`;

  if (meta !== undefined) {
    console.log(`${prefix} ${message}`, meta);
  } else {
    console.log(`${prefix} ${message}`);
  }
}

const logger = {
  error: (msg, meta) => log('error', msg, meta),
  warn: (msg, meta) => log('warn', msg, meta),
  info: (msg, meta) => log('info', msg, meta),
  debug: (msg, meta) => log('debug', msg, meta),
};

module.exports = logger;
