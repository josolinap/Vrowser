// Import the necessary libraries.
const puppeteer = require('puppeteer-core');
const express = require('express');
const path = require('path');
const http = require('http');

// Define the path to the installed Chrome executable within the Docker container.
const executablePath = '/usr/bin/google-chrome-stable';

// Create the Express application.
const app = express();
const PORT = process.env.PORT || 10000;

// Root endpoint to serve a basic HTML form.
// This allows a user to interact with the service through a web page.
app.get('/', (req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Virtual Browser Service</title>
        <style>
            body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #f0f2f5; color: #333; }
            .container { padding: 2em; background-color: #fff; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); text-align: center; }
            h1 { color: #4a90e2; }
            form { margin-top: 1em; }
            input[type="text"] { width: 300px; padding: 10px; border-radius: 5px; border: 1px solid #ccc; font-size: 16px; }
            button { padding: 10px 20px; background-color: #4a90e2; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; transition: background-color 0.3s; }
            button:hover { background-color: #357abd; }
            #loading { margin-top: 1em; color: #777; font-style: italic; display: none; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Virtual Browser Service</h1>
            <p>Enter a URL to get a screenshot:</p>
            <form id="urlForm">
                <input type="text" id="urlInput" name="url" placeholder="e.g., https://google.com" required>
                <button type="submit">Take Screenshot</button>
            </form>
            <p id="loading">Generating screenshot... this may take a moment.</p>
        </div>
        <script>
            const form = document.getElementById('urlForm');
            const urlInput = document.getElementById('urlInput');
            const loadingMessage = document.getElementById('loading');
            
            form.addEventListener('submit', async (e) => {
                e.preventDefault();
                const url = urlInput.value;
                if (url) {
                    loadingMessage.style.display = 'block';
                    window.location.href = \`/capture?url=\${encodeURIComponent(url)}\`;
                }
            });
        </script>
    </body>
    </html>
  `);
});

// Capture endpoint to handle the browser automation logic.
app.get('/capture', async (req, res) => {
  // Get the URL from the query parameters.
  const urlToCapture = req.query.url;

  if (!urlToCapture) {
    // If no URL is provided, send a bad request error.
    res.status(400).send('Error: Please provide a URL in the query parameters.');
    return;
  }

  // Use a try...catch...finally block to ensure the browser closes.
  let browser = null;
  try {
    console.log(`Launching browser for URL: ${urlToCapture}`);
    // Launch a new browser instance with flags required for the container environment.
    browser = await puppeteer.launch({
      executablePath,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--single-process' // Add this for some environments with limited resources
      ]
    });

    console.log('Opening a new page...');
    const page = await browser.newPage();
    
    // Set a timeout to prevent the page from hanging indefinitely.
    console.log(`Navigating to ${urlToCapture}...`);
    await page.goto(urlToCapture, { waitUntil: 'networkidle2' });
    
    console.log('Taking a screenshot...');
    // Take a screenshot and save it as a buffer.
    const screenshotBuffer = await page.screenshot({ type: 'png', fullPage: true });
    
    // Set the response headers and send the screenshot.
    res.writeHead(200, {
      'Content-Type': 'image/png',
      'Content-Length': screenshotBuffer.length
    });
    res.end(screenshotBuffer);
    
    console.log('Screenshot served successfully.');
    
  } catch (error) {
    console.error(`An error occurred: ${error.message}`);
    // Send a 500 status and the error message to the client.
    res.status(500).send(`An error occurred while generating the screenshot: ${error.message}`);
    
  } finally {
    // Ensure the browser is closed even if an error occurred.
    if (browser) {
      console.log('Closing the browser...');
      await browser.close();
    }
  }
});

// Start the server.
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
