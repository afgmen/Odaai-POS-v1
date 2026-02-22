'use strict';

const crypto = require('crypto');

/**
 * Verify GrabFood webhook HMAC-SHA256 signature.
 *
 * GrabFood sends the signature in the `X-GrabFood-Signature` header as:
 *   sha256=<hex-digest>
 *
 * @param {string|Buffer} rawBody  – raw request body (before JSON.parse)
 * @param {string} signatureHeader – value of X-GrabFood-Signature header
 * @param {string} secret          – GRAB_WEBHOOK_SECRET from .env
 * @returns {boolean}
 */
function verifyGrabSignature(rawBody, signatureHeader, secret) {
  if (!signatureHeader || !secret) return false;

  const [algo, digest] = signatureHeader.split('=');
  if (algo !== 'sha256' || !digest) return false;

  const expected = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');

  // Constant-time comparison to prevent timing attacks
  try {
    return crypto.timingSafeEqual(
      Buffer.from(digest, 'hex'),
      Buffer.from(expected, 'hex'),
    );
  } catch {
    return false;
  }
}

module.exports = { verifyGrabSignature };
