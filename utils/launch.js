import puppeteer from 'puppeteer-core';

export async function getBrowser() {
  return puppeteer.launch({
    headless: 'new',
    executablePath: process.env.PUPPETEER_EXEC_PATH || '/usr/bin/google-chrome-stable',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--disable-features=VizDisplayCompositor',
      '--no-first-run',
      '--no-zygote',
      '--single-process'
    ]
  });
}
