import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';

const page = readFileSync(new URL('./index.html', import.meta.url));
const port = Number(process.env.PORT || 80);

const server = createServer((request, response) => {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    response.writeHead(405, { Allow: 'GET, HEAD' });
    response.end();
    return;
  }

  const pathname = new URL(request.url, 'http://localhost').pathname;
  if (pathname === '/healthz') {
    response.writeHead(200, { 'Content-Type': 'application/json' });
    response.end('{"status":"ok"}');
    return;
  }

  if (pathname === '/' || pathname === '/index.html') {
    response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    response.end(page);
    return;
  }

  response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end('Nicht gefunden');
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Frontend listening on port ${port}`);
});

for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => server.close());
}
