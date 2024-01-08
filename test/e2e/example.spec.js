import { test } from '@playwright/test';

const domain = process.env['DOMAIN']

test('test', async ({ page }) => {
  console.log(domain)
  await page.goto('https://iconicompany.ru/idocs/tech/onboarding/');
});