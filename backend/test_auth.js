const child_process = require('child_process');
const http = require('http');
const path = require('path');

const server = child_process.fork(path.join(__dirname, 'server.js'), [], {
  silent: true,
});

server.stdout.on('data', (chunk) => process.stdout.write('SERVER: ' + chunk.toString()));
server.stderr.on('data', (chunk) => process.stderr.write('SERVER-ERR: ' + chunk.toString()));

function request(pathname, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: 5000,
        path: pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
        },
      },
      (res) => {
        let text = '';
        res.on('data', (chunk) => (text += chunk));
        res.on('end', () => resolve({ status: res.statusCode, body: text }));
      }
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

(async () => {
  await new Promise((resolve) => setTimeout(resolve, 1500));
  try {
    const email = `testuser${Date.now()}@example.com`;
    const reg = await request('/register', {
      fullname: 'Test User',
      email,
      password: 'Password123',
      phone: '1234567890',
    });
    console.log('REGISTER RESPONSE', reg);

    const login = await request('/login', {
      email,
      password: 'Password123',
    });
    console.log('LOGIN RESPONSE', login);
  } catch (error) {
    console.error('REQUEST ERROR', error);
  } finally {
    server.kill();
  }
})();
