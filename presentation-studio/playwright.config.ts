import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests/browser', timeout: 60000, fullyParallel: false, workers: 1,
  use: { browserName: (process.env.CYRUS_TEST_BROWSER ?? 'chromium') as 'chromium' | 'firefox' | 'webkit', channel: process.env.CYRUS_TEST_CHANNEL, baseURL: 'http://127.0.0.1:5190', viewport: { width: 1440, height: 900 }, headless: true, acceptDownloads: true, screenshot: 'only-on-failure', trace: 'retain-on-failure' },
  webServer: { command: 'npm run dev:studio', url: 'http://127.0.0.1:5190', reuseExistingServer: true, timeout: 30000 },
  reporter: [['list'], ['json', { outputFile: 'test-results/browser-results.json' }]],
});
