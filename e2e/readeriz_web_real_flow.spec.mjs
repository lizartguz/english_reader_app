import { expect, test } from '@playwright/test';
import { PNG } from 'pngjs';

import { apiBaseUrl, e2eCredentials } from './support/e2e_env.mjs';

const { clientEmail, clientPassword, adminEmail, adminPassword } =
  e2eCredentials({ includeAdmin: true });

test.describe('Readeriz Web real', () => {
  test.beforeAll(async ({ request }) => {
    await ensureStableDictionaryWord(request);
  });

  test('login, lector, modal de palabra y vocabulario funcionan con API real', async ({ page }) => {
    await page.goto('/');
    await expectPageNotBlank(page);
    await enableFlutterSemantics(page);

    const loginFields = page.locator('input[data-semantics-role="text-field"]');
    const emailBox = await visibleBox(loginFields.nth(0));
    const passwordBox = await visibleBox(loginFields.nth(1));
    const submitBox = await visibleBox(page.getByRole('button', { name: 'Iniciar sesión' }));
    await setFlutterSemanticsPointerEvents(page, 'none');
    await typeIntoFlutterCanvasField(page, emailBox, clientEmail);
    await typeIntoFlutterCanvasField(page, passwordBox, clientPassword);
    await clickBoxCenter(page, submitBox);
    await enableFlutterSemantics(page);

    const story = page.getByRole('button', { name: /Abrir historia .*, nivel/i }).first();
    await expect(story).toBeVisible({ timeout: 60_000 });
    await filterStoriesWithoutMatches(page);
    await clickFlutterControl(page, story);
    await enableFlutterSemantics(page);

    await expect(page.getByRole('heading')).toBeVisible();
    const word = page.getByRole('button', { name: 'Consultar palabra umbrella' }).first();
    await expect(word).toBeVisible();
    await clickFlutterControl(page, word);
    await enableFlutterSemantics(page);

    await expect(page.getByText('Traducción')).toBeVisible();
    const saveButton = page.getByRole('button', {
      name: /Guardar palabra|Guardar .* en vocabulario|Guardada/
    }).first();
    await expect(saveButton).toBeVisible();
    const savedState = page.getByText(/Guardada|ya esta guardada/).first();
    if (!(await savedState.isVisible().catch(() => false))) {
      await clickFlutterControl(page, saveButton);
      await expect(savedState).toBeVisible();
    }

    await page.keyboard.press('Escape');
    await page.goBack();
    await enableFlutterSemantics(page);
    await clickFlutterControl(page, page.getByRole('button', { name: 'Vocabulario' }));
    await enableFlutterSemantics(page);

    await expect(page.getByRole('heading', { name: 'Vocabulario' })).toBeVisible();
    const savedWord = page.getByLabel(/Palabra guardada umbrella/);
    await expect(savedWord).toBeVisible();
    await expect(page.getByRole('button', { name: 'Acciones para umbrella' })).toBeVisible();

    await filterVocabularyByStatus(page, 'Archivada');
    await expect(savedWord).toBeHidden();
    await expect(clearFiltersButton(page)).toBeVisible();

    await filterVocabularyByStatus(page, 'Todas');
    await expect(savedWord).toBeVisible();
    await expect(clearFiltersButton(page)).toBeHidden();
    await expectPageNotBlank(page);
  });
});

/// Comprueba búsqueda, estado sin coincidencias y limpieza de filtros en historias.
async function filterStoriesWithoutMatches(page) {
  const searchField = page.getByLabel('Buscar historias');
  await expect(searchField).toBeVisible();
  const searchBox = await visibleBox(searchField);
  await setFlutterSemanticsPointerEvents(page, 'none');
  await typeIntoFlutterCanvasField(page, searchBox, 'zzzznomatch');
  await enableFlutterSemantics(page);

  await expect(clearFiltersButton(page)).toBeVisible();
  await clickFlutterControl(page, clearFiltersButton(page));
  await enableFlutterSemantics(page);
  await expect(clearFiltersButton(page)).toBeHidden();
}

/// Aplica un chip de estado del vocabulario, expuesto como casilla por Flutter.
async function filterVocabularyByStatus(page, label) {
  const chip = page.getByRole('checkbox', { name: new RegExp(label) }).first();
  await clickFlutterControl(page, chip);
  await enableFlutterSemantics(page);
}

/// Localiza la acción de recuperación del estado sin coincidencias.
function clearFiltersButton(page) {
  return page.getByRole('button', { name: 'Quitar filtros' });
}

/// Asegura un dato local estable para no depender de proveedores externos.
async function ensureStableDictionaryWord(request) {
  const loginResponse = await request.post(`${apiBaseUrl}/auth/login`, {
    data: {
      email: adminEmail,
      password: adminPassword,
      clientType: 'mobile'
    }
  });
  expect(loginResponse.ok()).toBeTruthy();
  const loginBody = await loginResponse.json();
  const accessToken = loginBody.data.accessToken;

  const createResponse = await request.post(`${apiBaseUrl}/admin/words`, {
    headers: {
      Authorization: `Bearer ${accessToken}`
    },
    data: {
      word: 'umbrella',
      language: 'en',
      definitionEn: 'A device held above the head for protection from rain.',
      partOfSpeech: 'noun',
      source: 'readeriz-e2e',
      translations: [
        {
          targetLanguage: 'es',
          translation: 'paraguas',
          meaningContext: 'Objeto usado para cubrirse de la lluvia.',
          source: 'readeriz-e2e'
        }
      ],
      examples: [
        {
          exampleText: 'Mia carries a red umbrella.',
          source: 'readeriz-e2e',
          sortOrder: 0
        }
      ]
    }
  });

  expect([201, 409]).toContain(createResponse.status());
}

/// Escribe sobre el canvas real para que Flutter actualice su controlador.
async function typeIntoFlutterCanvasField(page, box, value) {
  await clickBoxCenter(page, box);
  await page.waitForTimeout(250);
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.type(value, { delay: 10 });
}

/// Hace click en el centro visual del control para interactuar con el canvas real.
async function clickFlutterControl(page, locator) {
  const box = await visibleBox(locator);
  await setFlutterSemanticsPointerEvents(page, 'none');
  await clickBoxCenter(page, box);
  await page.waitForTimeout(300);
  await setFlutterSemanticsPointerEvents(page, 'auto');
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

/// Evita falsos positivos cuando el canvas Web queda blanco por un fallo visual.
async function expectPageNotBlank(page) {
  await expect
    .poll(async () => countPaintedPixels(await page.screenshot({ fullPage: true })), {
      timeout: 30_000
    })
    .toBeGreaterThan(20);
}

/// Cuenta una muestra de píxeles que se alejan del blanco del navegador.
function countPaintedPixels(screenshot) {
  const image = PNG.sync.read(screenshot);
  let paintedPixels = 0;
  for (let index = 0; index < image.data.length; index += 4 * 40) {
    const red = image.data[index];
    const green = image.data[index + 1];
    const blue = image.data[index + 2];
    const alpha = image.data[index + 3];
    if (alpha > 0 && (red < 250 || green < 250 || blue < 250)) {
      paintedPixels += 1;
    }
  }
  return paintedPixels;
}
