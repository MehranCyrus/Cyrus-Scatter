import type { Page } from '@playwright/test';

/** Exercise the visible menu rather than calling a hidden action directly. */
export async function menuAction(page: Page, menu: 'project-menu' | 'output-menu', item: string) {
  const summary = page.getByTestId(menu);
  if (!await summary.evaluate(element => element.parentElement?.hasAttribute('open'))) await summary.click();
  await page.getByTestId(item).click();
}
