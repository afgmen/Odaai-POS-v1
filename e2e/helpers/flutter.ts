import { Page, Locator } from '@playwright/test';

/**
 * Flutter Web DOM helpers for Playwright E2E tests.
 *
 * Flutter 3.41 web (CanvasKit renderer, dart2js production build) renders via
 * WebGL canvas. The accessibility tree (<flt-semantics> nodes) is a separate
 * DOM overlay that is built only after the first user interaction.
 *
 * Boot sequence (production build):
 *   1. flutter_bootstrap.js → injects main.dart.js
 *   2. Flutter engine mounts: flutter-view, flt-glass-pane, flt-semantics-host,
 *      flt-semantics-placeholder (~2–3 s on first load)
 *   3. JS click on flt-semantics-placeholder → flt-semantics tree is built
 *
 * NOTE: flt-semantics-placeholder is position:fixed outside the viewport.
 *   Use page.evaluate to dispatch PointerEvents instead of page.click().
 *
 * Reference: https://docs.flutter.dev/platform-integration/web/renderers
 */

/**
 * Wait for the Flutter app to finish initial rendering.
 * Requires the production build (flutter build web) served via HTTP.
 */
export async function waitForFlutter(page: Page, timeout = 30_000) {
  // Wait for Flutter to mount its custom elements
  await page.waitForFunction(
    () => document.querySelector('flt-glass-pane') !== null,
    { timeout },
  );
  // Give Flutter a moment to render the first frame
  await page.waitForTimeout(1_000);
}

/**
 * Enable Flutter's accessibility / semantics tree.
 *
 * flt-semantics-placeholder sits outside the viewport (position: fixed, off-screen).
 * A regular Playwright click fails because it requires the element to be in viewport.
 * We use evaluate() to dispatch PointerEvents directly, which Flutter listens to
 * in order to build the <flt-semantics> overlay tree.
 */
export async function enableA11y(page: Page) {
  // Dispatch pointer events on flt-semantics-placeholder via JS
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph) {
      ph.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, cancelable: true }));
      ph.dispatchEvent(new PointerEvent('pointerup',   { bubbles: true, cancelable: true }));
      (ph as HTMLElement).click();
    }
  });
  await page.waitForTimeout(500);

  // Wait for flt-semantics nodes to appear
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics').length > 0,
    { timeout: 10_000 },
  ).catch(() => {
    // If semantics tree didn't appear, continue — some screens may not need it
  });

  await page.waitForTimeout(300);
}

/**
 * Find a Flutter semantic node by its aria-label.
 */
export function flutterText(page: Page, text: string): Locator {
  return page.locator(`flt-semantics[aria-label="${text}"]`);
}

/**
 * Find a Flutter button by its aria-label and click it.
 */
export async function tapButton(page: Page, label: string) {
  const btn = page.locator(`flt-semantics[role="button"][aria-label="${label}"]`);
  await btn.waitFor({ state: 'visible' });
  await btn.click();
  await page.waitForTimeout(200);
}

/**
 * Type into a Flutter text field identified by its aria-label.
 */
export async function typeInField(page: Page, label: string, value: string) {
  const field = page.locator(
    `flt-semantics[role="textbox"][aria-label="${label}"], ` +
    `flt-semantics[contenteditable][aria-label="${label}"]`,
  );
  await field.waitFor({ state: 'visible' });
  await field.click();
  await page.keyboard.type(value, { delay: 30 });
}

/**
 * Login as an employee via Select Employee dropdown + PIN keypad.
 *
 * Flow:
 *   1. Click "Select Employee" button → dropdown opens
 *   2. Click the first menuitem (or one matching employeeNamePattern)
 *   3. Type PIN digit-by-digit on the on-screen keypad
 *   4. Click "Login"
 *
 * @param page         Playwright Page
 * @param pin          4-digit PIN (default: '1234' for Administrator)
 * @param employeePattern  Regex to match employee name (default: first available)
 */
export async function loginEmployee(
  page: Page,
  pin = '1234',
  employeePattern?: RegExp,
) {
  // 1. Click "Select Employee"
  const selectBtn = page.locator('flt-semantics[role="button"]')
    .filter({ hasText: /select employee/i }).first();
  await selectBtn.waitFor({ state: 'visible', timeout: 10_000 });
  await selectBtn.click();
  await page.waitForTimeout(600);

  // 2. Select employee from dropdown
  const empItem = employeePattern
    ? page.locator('flt-semantics[role="menuitem"]').filter({ hasText: employeePattern }).first()
    : page.locator('flt-semantics[role="menuitem"]').first();
  await empItem.waitFor({ state: 'visible', timeout: 5_000 });
  await empItem.click();
  await page.waitForTimeout(600);

  // 3. Enter PIN on the on-screen keypad
  for (const digit of pin) {
    const digitBtn = page.locator('flt-semantics[role="button"]')
      .filter({ hasText: new RegExp(`^${digit}$`) }).first();
    await digitBtn.click();
    await page.waitForTimeout(80);
  }

  // 4. Click "Login"
  const loginBtn = page.locator('flt-semantics[role="button"]')
    .filter({ hasText: /^login$/i }).first();
  await loginBtn.click();

  // Wait for POS main screen to load (navigation buttons appear)
  await page.waitForFunction(
    () => {
      const btns = document.querySelectorAll('flt-semantics[role="button"]');
      return Array.from(btns).some(b => b.textContent?.trim() === 'POS');
    },
    { timeout: 15_000 },
  );
  await page.waitForTimeout(500);
}
