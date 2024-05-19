const http = require('http');
const port = 8080;

const requestHandler = (req, res) => {
  console.log(JSON.stringify(req.headers));
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', () => {
    console.log(JSON.stringify(JSON.parse(body)));
    if (req.url === '/') {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('Hello World! from Server');
    } else {
      res.writeHead(404);
      res.end();
    }
  });
};

const server = http.createServer(requestHandler);

server.listen(port, () => {
  console.log('Server is ready');
  console.log(`Server listening on port ${port}`);
});

