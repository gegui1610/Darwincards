import { createServer } from 'node:http';
import express from 'express';
import { ExpressPeerServer } from 'peer';

const app = express();
app.disable('x-powered-by');
const server = createServer(app);

// A página usa path:'/api' e key:'peerjs', portanto o endpoint é /api/peerjs.
const peerServer = ExpressPeerServer(server, {
  path: '/api',
  key: 'peerjs',
  proxied: true,
  allow_discovery: false,
  expire_timeout: 5000,
  alive_timeout: 60000,
});

// O Vercel encaminha /api/* para esta função catch-all. O servidor HTTP é exportado
// para que a função aceite upgrades WebSocket, conforme o runtime Node do Vercel.
app.use('/', peerServer);

export default server;
