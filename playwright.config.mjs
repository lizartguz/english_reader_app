import { defineConfig, devices } from '@playwright/test';
import { fileURLToPath } from 'node:url';

const apiBaseUrl = process.env.API_BASE_URL ?? 'http://localhost:3000/api/v1';
const apiHealthUrl = `${apiBaseUrl.replace(/\/$/, '')}/health`;
const webPort = process.env.E2E_WEB_PORT ?? '53633';
const webBaseUrl = process.env.E2E_WEB_BASE_URL ?? `http://localhost:${webPort}`;
const apiProjectDir = fileURLToPath(new URL('../english_reader_api/', import.meta.url));

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  timeout: 120_000,
  expect: {
    timeout: 30_000
  },
  use: {
    baseURL: webBaseUrl,
    launchOptions: {
      args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader']
    },
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure'
  },
  webServer: [
    {
      command: 'npm.cmd run start',
      cwd: apiProjectDir,
      url: apiHealthUrl,
      reuseExistingServer: true,
      timeout: 120_000
    },
    {
      // Sin reutilizar el servidor Web: garantiza que cada corrida valide el build actual.
      command: `cmd /c flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=${apiBaseUrl} --dart-define=APP_ENV=development && npx.cmd http-server build/web -a localhost -p ${webPort} -c-1`,
      url: webBaseUrl,
      reuseExistingServer: false,
      timeout: 300_000
    }
  ],
  projects: [
    {
      name: 'chrome-desktop',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
        viewport: { width: 1366, height: 768 }
      }
    },
    {
      name: 'chrome-mobile-viewport',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
        viewport: { width: 390, height: 844 },
        deviceScaleFactor: 2,
        isMobile: false,
        hasTouch: true
      }
    }
  ]
});
