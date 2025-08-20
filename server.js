import express from 'express';
import { getBrowser } from './utils/launch.js';

const app = express();
const port = process.env.PORT || 10000;

app.get('/health', (_req, res) => res.send('OK'));

app.get('/', async (_req, res) => {
  let browser;
  try {
    browser = await getBrowser();
    const page = await browser.newPage();
    await page.goto('https://example.com', { waitUntil: 'networkidle0' });
    const title = await page.title();
    res.json({ title });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  } finally {
    if (browser) await browser.close();
  }
});

app.listen(port, () => console.log(`Listening on :${port}`));
