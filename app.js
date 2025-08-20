// Import the puppeteer-core library.
// We use `puppeteer-core` because we are providing our own browser executable
// inside the Docker container, which keeps the image size small.
const puppeteer = require('puppeteer-core');
const path = require('path');
const http = require('http');

// Define the path to the installed Chrome executable within the Docker container.
// This is the path where the `apt-get install` command placed the browser.
const executablePath = '/usr/bin/google-chrome-stable';

// This is a simple function to handle a basic request.
// It will launch a browser, navigate to a page, take a screenshot, and serve it.
const server = http.createServer(async (req, res) => {
  // Check if the request is for the root URL
  if (req.url === '/') {
    try {
      console.log('Launching browser...');
      // Launch a new browser instance with specific arguments needed for the
      // container environment.
      // The `--no-sandbox` flag is essential for running in Docker.
      const browser = await puppeteer.launch({
        executablePath,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-gpu'
        ]
      });

      console.log('Opening a new page...');
      const page = await browser.newPage();
      
      console.log('Navigating to example.com...');
      await page.goto('https://example.com');
      
      console.log('Taking a screenshot...');
      // Take a screenshot and save it as a buffer.
      const screenshotBuffer = await page.screenshot({ type: 'png' });
      
      console.log('Closing the browser...');
      await browser.close();
      
      // Set the response headers to indicate a PNG image.
      res.writeHead(200, {
        'Content-Type': 'image/png',
        'Content-Length': screenshotBuffer.length
      });
      
      // Send the screenshot data as the response.
      res.end(screenshotBuffer);
      
      console.log('Screenshot served successfully.');
      
    } catch (error) {
      console.error('An error occurred:', error);
      // If an error occurs, send an error response to the client.
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('An error occurred while generating the screenshot.');
    }
  } else {
    // Handle other URLs
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 Not Found');
  }
});

// The server will listen on port 10000, as exposed in the Dockerfile.
const PORT = process.env.PORT || 10000;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
