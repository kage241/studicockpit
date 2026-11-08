// Baut index.html und sw.js aus src/app.html.
// Aufruf: node build.js
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const root = __dirname;
let src = fs.readFileSync(path.join(root, 'src', 'app.html'), 'utf8');

// Kopfzeilen der Quelle (für die claude.ai-Version gedacht) entfernen – sie stehen im <head> unten.
src = src
  .replace(/^<title>.*<\/title>\s*/m, '')
  .replace(/^<meta name="claude:viewport-fit-sides"[^>]*>\s*/m, '')
  .replace(/^<link rel="preconnect"[^>]*>\s*/m, '')
  .replace(/^<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com[^>]*>\s*/m, '');

const head = `<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>StudiCockpit</title>
<meta name="description" content="Persönliches Studien-Cockpit für B. Sc. Sportwissenschaft an der Ruhr-Universität Bochum.">
<meta name="theme-color" content="#0E1014">
<meta name="mobile-web-app-capable" content="yes">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" type="image/png" href="icons/icon-192.png">
<link rel="apple-touch-icon" href="icons/icon-192.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Inter:wght@400;500;600&display=swap">
<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>
</head>
<body>
`;
const fuss = `
<script>
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () { navigator.serviceWorker.register('sw.js').catch(function () {}); });
}
</script>
</body>
</html>
`;
const html = head + src + fuss;
fs.writeFileSync(path.join(root, 'index.html'), html);

const version = crypto.createHash('sha1').update(html).digest('hex').slice(0, 10);
const sw = fs.readFileSync(path.join(root, 'src', 'sw.template.js'), 'utf8').replace('__VERSION__', version);
fs.writeFileSync(path.join(root, 'sw.js'), sw);
console.log('index.html und sw.js gebaut, Version ' + version);
