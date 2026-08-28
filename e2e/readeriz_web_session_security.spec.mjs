import { expect, test } from '@playwright/test';

/**
 * FLT-SEC-004 — el refresh token no debe persistirse en el cliente Web.
 *
 * Comprueba contra la API real que en Flutter Web la sesión viaja como espera
 * la auditoría: refresh token en cookie `HttpOnly` que JavaScript no puede
 * leer, access token solo en memoria, y nada de tokens en el almacenamiento
 * del navegador. También verifica que la sesión sobreviva a una recarga, que es
 * la contrapartida de no persistir nada.
 */

const clientEmail = process.env.E2E_CLIENT_EMAIL ?? 'cliente.flutter.test@englishreader.local';
const clientPassword = process.env.E2E_CLIENT_PASSWORD ?? 'Cliente123*';
const refreshCookieName = process.env.E2E_REFRESH_COOKIE ?? 'er_refresh_token';

test.describe('Sesión Web segura', () => {
  test('no deja tokens en el navegador y recupera la sesión al recargar', async ({ page }) => {
    const loginResponse = page.waitForResponse(
      (response) => response.url().includes('/auth/login') && response.request().method() === 'POST'
    );

    await page.goto('/');
    await enableFlutterSemantics(page);
    await signIn(page);

    // 1. La API no debe devolver el refresh token en el cuerpo para app_web.
    const body = await (await loginResponse).json();
    expect(body.data.accessToken).toBeTruthy();
    expect(body.data.refreshToken ?? null).toBeNull();

    await expect(page.getByRole('button', { name: /Abrir historia .*, nivel/i }).first()).toBeVisible({
      timeout: 60_000
    });

    // 2. La cookie de refresco existe y es HttpOnly, así que ni un XSS la lee.
    const cookies = await page.context().cookies();
    const refreshCookie = cookies.find((cookie) => cookie.name === refreshCookieName);
    expect(refreshCookie, `no se emitió la cookie ${refreshCookieName}`).toBeTruthy();
    expect(refreshCookie.httpOnly).toBe(true);

    const visibleParaJs = await page.evaluate(() => document.cookie);
    expect(visibleParaJs).not.toContain(refreshCookieName);

    // 3. Ningún token queda en el almacenamiento del navegador. `flutter_secure_storage`
    //    usa localStorage en Web, así que persistirlos equivaldría a dejarlos a la vista.
    const almacenados = await page.evaluate(() => {
      const volcar = (storage) => Object.entries({ ...storage });
      return [...volcar(window.localStorage), ...volcar(window.sessionStorage)];
    });
    const sospechosos = almacenados.filter(
      ([clave, valor]) =>
        /token/i.test(clave) ||
        // Un JWT en el valor delataría el token aunque la clave se llame de otro modo.
        /^ey[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\./.test(String(valor))
    );
    expect(sospechosos, `tokens hallados en el navegador: ${JSON.stringify(sospechosos)}`).toEqual([]);

    // 4. La contrapartida: sin nada persistido, la sesión debe rehacerse con la
    //    cookie al recargar. Si esto falla, el usuario perdería la sesión en cada F5.
    const refreshResponse = page.waitForResponse(
      (response) => response.url().includes('/auth/refresh') && response.request().method() === 'POST'
    );
    await page.reload();
    await enableFlutterSemantics(page);
    expect((await refreshResponse).status()).toBe(200);

    await expect(page.getByRole('button', { name: /Abrir historia .*, nivel/i }).first()).toBeVisible({
      timeout: 60_000
    });
  });
});

async function signIn(page) {
  const loginFields = page.locator('input[data-semantics-role="text-field"]');
  const emailBox = await visibleBox(loginFields.nth(0));
  const passwordBox = await visibleBox(loginFields.nth(1));
  const submitBox = await visibleBox(page.getByRole('button', { name: 'Iniciar sesión' }));

  await setFlutterSemanticsPointerEvents(page, 'none');
  await typeIntoFlutterCanvasField(page, emailBox, clientEmail);
  await typeIntoFlutterCanvasField(page, passwordBox, clientPassword);
  await clickBoxCenter(page, submitBox);
  await enableFlutterSemantics(page);
}

/// Escribe sobre el canvas real para que Flutter actualice su controlador.
async function typeIntoFlutterCanvasField(page, box, value) {
  await clickBoxCenter(page, box);
  await page.waitForTimeout(250);
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.type(value, { delay: 10 });
}

/// Obtiene la caja visible de un nodo semántico antes de operar por coordenadas.
async function visibleBox(locator) {
  await locator.waitFor({ state: 'attached' });
  const box = await locator.boundingBox();
  if (!box) {
    throw new Error('El control Flutter no tiene una posicion visible.');
  }
  return box;
}

/// Centraliza el click por coordenadas para controles renderizados en canvas.
async function clickBoxCenter(page, box) {
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

/// Activa el árbol semántico de Flutter Web para que Playwright use la UI real.
async function enableFlutterSemantics(page) {
  await page.locator('flutter-view').waitFor({ state: 'attached' });
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.click();
  });
  await page.locator('flt-semantics-host').waitFor({ state: 'attached' });
  await setFlutterSemanticsPointerEvents(page, 'auto');
}

/// Cambia si la capa semántica recibe eventos o deja pasar clicks al canvas.
async function setFlutterSemanticsPointerEvents(page, value) {
  await page.evaluate((pointerEvents) => {
    document.querySelector('flt-semantics-host')?.style.setProperty('pointer-events', pointerEvents);
  }, value);
}
