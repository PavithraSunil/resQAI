const express = require('express');
const http = require('http');
const authRouter = require('./routes/auth');

const app = express();
app.use(express.json());
app.use(authRouter);

const server = app.listen(5001, () => {
  console.log('TEST SERVER running on 5001');
  const email = `testuser${Date.now()}@example.com`;
  const data = JSON.stringify({ fullname: 'Test User', email, password: 'Password123', phone: '1234567890' });
  const opts = {
    hostname: '127.0.0.1',
    port: 5001,
    path: '/register',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data),
    },
  };
  const req = http.request(opts, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
      console.log('REGISTER', res.statusCode, body);
      server.close();
    });
  });
  req.on('error', (error) => {
    console.error('REQUEST ERROR', error);
    server.close();
  });
  req.write(data);
  req.end();
});
