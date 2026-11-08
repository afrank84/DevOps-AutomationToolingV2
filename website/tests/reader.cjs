// Browser regression checks; serves files but never executes repository tools.
// Run with Playwright available: node website/tests/reader.cjs [base-url]
const { chromium } = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');

(async () => {
  const base = (process.argv[2] || 'http://127.0.0.1:8002').replace(/\/$/, '');
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium',
    headless: true,
    args: ['--no-sandbox'],
  });
  try {
    const page = await browser.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(base + '/');
    if (!await page.locator('.tool-card').count()) await page.goto(base + '/catalog.html');
    const links = await page.locator('.tool-card').evaluateAll(cards => cards.map(card => card.getAttribute('href')));
    assert(links.length > 0, 'Catalog must contain tools');
    for (const link of process.argv.includes('--smoke') ? links.slice(0, 1) : links) {
      assert(link.startsWith('guide.html?file='), 'File cards must open the reader');
      await page.goto(base + '/' + link);
      await page.locator('#views:not([hidden])').waitFor();
      assert((await page.locator('#guide').innerText()).trim(), 'Every file must have readable on-site content');
    }
    console.log(`${process.argv.includes('--smoke') ? 1 : links.length} catalog file links opened successfully`);
    await page.goto(base + '/guide.html?file=Conversion%2FConvert-CsvToJson.py');
    await page.locator('.file-explanation').waitFor();
    assert((await page.locator('.file-explanation').innerText()).includes('pandas.read_csv'));
    assert(!await page.locator('details').getAttribute('open'), 'Complete folder guide is secondary');
    await page.getByRole('button', { name: 'Folder Markdown', exact: true }).click();
    assert.equal(await page.locator('#markdown-text').textContent(), fs.readFileSync('Conversion/README.md', 'utf8'));
    await page.getByRole('button', { name: 'Source code', exact: true }).click();
    await page.waitForFunction(() => document.getElementById('source-text').textContent.startsWith('import pandas'));
    assert.equal(await page.locator('#source-text').textContent(), fs.readFileSync('Conversion/Convert-CsvToJson.py', 'utf8'));
    await page.reload();
    await page.locator('#views:not([hidden])').waitFor();
    assert(await page.locator('#source').isVisible());
    await page.goBack();
    assert(await page.locator('#markdown').isVisible());
    await page.getByRole('button', { name: 'How it works', exact: true }).click();
    await page.setViewportSize({ width: 390, height: 844 });
    assert(!await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), 'Mobile must not overflow');
    await page.goto(base + '/guide.html?file=General%2Ftimer.html');
    await page.locator('#views:not([hidden])').waitFor();
    assert(await page.getByRole('link', { name: 'Open interactive tool' }).isVisible());
    assert.equal(await page.locator('#display').count(), 0, 'HTML tool must not execute in the reader');
    await page.goto(base + '/guide.html?file=SSH%2FGet-SshKey.ps1');
    await page.locator('#views:not([hidden])').waitFor();
    await page.getByText('Read the complete folder guide', { exact: true }).click();
    await page.getByRole('link', { name: 'Choose an implementation', exact: true }).click();
    assert(await page.locator('#choose-an-implementation').isVisible(), 'Folder TOC must work');
    await page.route('**/Conversion/README.md', route => route.fulfill({
      contentType: 'text/plain',
      body: '# Test\n<img src=x onerror="window.injected=true"><script>window.injected=true</script>\n[bad](javascript:alert(1))',
    }));
    await page.goto(base + '/guide.html?file=Conversion%2FConvert-CsvToJson.py');
    await page.locator('#views:not([hidden])').waitFor();
    assert(!await page.evaluate(() => window.injected));
    assert.equal(await page.locator('#guide script, #guide [onerror], #guide a[href^="javascript:"]').count(), 0);
    await page.goto(base + '/guide.html?file=..%2Fsecret');
    await page.waitForFunction(() => document.getElementById('status').textContent.includes('not in the documentation index'));
    assert.deepEqual(errors, []);
    console.log('Explanation selection, exact Markdown/source, history, mobile, HTML isolation, TOC, sanitization, and invalid-path checks passed');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
