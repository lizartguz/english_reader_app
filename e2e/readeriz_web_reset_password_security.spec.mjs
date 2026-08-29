import { expect, test } from '@playwright/test';

/**
 * FLT-SEC-011 — el token de reset no debe quedarse en la URL del navegador.
 *
 * La prueba abre el enlace como lo haria el correo, verifica que la barra queda
 * sin `token`, y confirma que el formulario aun envia ese token a la API.
 */

const resetToken = 'reset-e2e-token';

test.describe('Reset password Web seguro', () => {
  test('limpia el token de la URL y lo conserva para enviar el formulario', async ({ page }) => {
    const resetRequest = page.waitForRequest(
      (request) => request.url().includes('/auth/reset-password') && request.method() === 'POST'
    );

    await page.route('**/auth/reset-password', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          message: 'Contrasena actualizada.',
          data: {}
        })
      });
    });

    await page.goto(`/#/reset-password?token=${resetToken}&src=email`);
    await enableFlutterSemantics(page);

    await expect.poll(() => page.url(), { timeout: 30_000 }).not.toContain('token=');
    expect(page.url()).toContain('src=email');

    const fields = page.locator('input[data-semantics-role="text-field"]');
    const passwordBox = await visibleBox(fields.nth(1));
    const submitBox = await visibleBox(page.getByRole('button', { name: /Guardar contrase(?:n|ñ)a/ }));

    await setFlutterSemanticsPointerEvents(page, 'none');
    await typeIntoFlutterCanvasField(page, passwordBox, 'Cliente123');
    await clickBoxCenter(page, submitBox);
    await enableFlutterSemantics(page);

    const payload = (await resetRequest).postDataJSON();
    expect(payload.token).toBe(resetToken);
    expect(payload.password).toBe('Cliente123');
  });
});

/// Escribe sobre el canvas real para que Flutter actualice su controlador.
async function typeIntoFlutterCanvasField(page, box, value) {
  await clickBoxCenter(page, box);
  await page.waitForTimeout(250);
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.type(value, { delay: 10 });
}

/// Obtiene la caja visible de un nodo semantico antes de operar por coordenadas.
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

/// Activa el arbol semantico de Flutter Web para que Playwright use la UI real.
async function enableFlutterSemantics(page) {
  await page.locator('flutter-view').waitFor({ state: 'attached' });
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.click();
  });
  await page.locator('flt-semantics-host').waitFor({ state: 'attached' });
  await setFlutterSemanticsPointerEvents(page, 'auto');
}

/// Cambia si la capa semantica recibe eventos o deja pasar clicks al canvas.
async function setFlutterSemanticsPointerEvents(page, value) {
  await page.evaluate((pointerEvents) => {
    document.querySelector('flt-semantics-host')?.style.setProperty('pointer-events', pointerEvents);
  }, value);
}
