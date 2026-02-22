import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright E2E configuration for Oda POS Flutter Web.
 *
 * Flutter web (CanvasKit renderer, dart2js) requires GPU/WebGL to render.
 * Serve the production build before running tests:
 *
 *   flutter build web --no-pub
 *   python3 -m http.server 8080 --directory build/web
 *   npx playwright test
 *
 * NOTE: headless: false is needed because CanvasKit uses WebGL canvas.
 *   The flt-semantics a11y tree is activated via JS click on
 *   flt-semantics-placeholder (see e2e/helpers/flutter.ts).
 */
export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,        // POS flows share local SQLite state
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,                  // sequential — one browser at a time
  reporter: [['html', { open: 'never' }], ['list']],
  timeout: 60_000,

  use: {
    baseURL: 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    // headless: false → browser has real GPU context for WebGL/CanvasKit
    headless: false,
  },

  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        headless: false,
        launchOptions: {
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
          ],
        },
      },
    },
  ],

  // Auto-serve the production build (flutter build web must run first):
  webServer: {
    command: 'python3 -m http.server 8080 --directory build/web',
    port: 8080,
    reuseExistingServer: true,
    timeout: 10_000,
  },
});
