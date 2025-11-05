import { test, expect } from '@playwright/test'

test.describe('Knowsee chat UI', () => {
  test('renders the shell and sidebar', async ({ page }) => {
    await page.goto('/')

    await expect(page.getByRole('heading', { name: 'Knowsee' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'New chat' })).toBeVisible()
    await expect(page.getByTestId('message-empty-state')).toBeVisible()
  })

  test('accepts user input', async ({ page }) => {
    await page.goto('/')

    const input = page.getByPlaceholder('Type your message... (Shift+Enter for new line)')
    await input.fill('Hello from Playwright')
    await page.getByRole('button', { name: 'Send message' }).click()

    await expect(
      page.getByTestId('message-list').getByText('Hello from Playwright').first()
    ).toBeVisible()
  })
})
