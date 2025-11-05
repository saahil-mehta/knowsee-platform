const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to the app
    console.log('Navigating to http://localhost:3000...');
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle', timeout: 30000 });

    // Take a screenshot of the landing page
    await page.screenshot({ path: 'landing.png', fullPage: true });
    console.log('Landing page screenshot saved');

    // Check if we need to login
    const loginForm = await page.locator('input[type="email"], input[type="text"][name*="mail"], input[placeholder*="mail"]').first();
    if (await loginForm.isVisible({ timeout: 5000 }).catch(() => false)) {
      console.log('Login form detected, attempting to log in with a@test.com...');

      // Fill in login form
      await loginForm.fill('a@test.com');
      const passwordInput = await page.locator('input[type="password"]').first();
      await passwordInput.fill('a');

      // Click login button
      const loginButton = await page.locator('button[type="submit"], button:has-text("Sign In"), button:has-text("Log In")').first();
      await loginButton.click();

      // Wait for navigation
      await page.waitForLoadState('networkidle', { timeout: 10000 });
      await page.screenshot({ path: 'after_login.png', fullPage: true });
      console.log('After login screenshot saved');
    }

    // Look for admin/settings area
    const currentUrl = page.url();
    console.log('Current URL:', currentUrl);

    // Try to navigate to admin connector setup
    console.log('Navigating to admin connector page...');
    await page.goto('http://localhost:3000/admin/connectors', { waitUntil: 'networkidle', timeout: 30000 });
    await page.screenshot({ path: 'admin_connectors.png', fullPage: true });
    console.log('Admin connectors screenshot saved');

    // Look for Google Drive connector
    const gdrive = await page.locator('text=/Google Drive/i').first();
    if (await gdrive.isVisible({ timeout: 5000 }).catch(() => false)) {
      console.log('Found Google Drive connector');
      await gdrive.click();
      await page.waitForTimeout(2000);
      await page.screenshot({ path: 'gdrive_config.png', fullPage: true });
      console.log('Google Drive config screenshot saved');
    }

    // Get all visible text on the page
    const bodyText = await page.locator('body').textContent();
    console.log('\n=== PAGE CONTENT ===');
    console.log(bodyText.substring(0, 2000)); // First 2000 chars

  } catch (error) {
    console.error('Error:', error.message);
    await page.screenshot({ path: 'error.png', fullPage: true });
  } finally {
    await browser.close();
  }
})();
