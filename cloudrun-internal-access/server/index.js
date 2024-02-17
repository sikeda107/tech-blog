const http = require('http');
const port = 8080;
const requestHandler = (req, res) => {
  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hello World! from Server');
  } else {
    res.writeHead(404);
    res.end();
  }
};
const server = http.createServer(requestHandler);
server.listen(port, () => {
  console.log('Server is ready');
  console.log(`Server listening on port ${port}`);
});
// SIGTERM と SIGINT シグナルに対してリスナーを設定
const gracefulShutdown = async () => {
  console.log('Server is shutting down');
  server.close(() => {
    console.log('Server shut down complete');
    process.exit(0);
  });
};
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
