const { execSync } = require('child_process');
const http = require('http');
const https = require('https');
const domain = process.env.DOMAIN || 'checkip.dyndns.com';
const url = `https://${domain}`;
const port = 8080;

// サーバーを作成
const server = http.createServer((req, res) => {
  if (req.url === '/') {
    const stdout = execSync(`dig ${domain} +short`).toString();
    console.log(`stdout: ${JSON.stringify(stdout)}`);
    const options = new URL(url);
    https
      .get(options, (httpRes) => {
        let data = '';
        httpRes.on('data', (chunk) => {
          data += chunk;
        });
        httpRes.on('end', () => {
          // レスポンスをブラウザに表示
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.write(data);
          res.end();
        });
      })
      .on('error', (e) => {
        console.error(`エラーが発生しました: ${e.message}`);
        res.writeHead(500);
        res.write('サーバーエラーが発生しました');
        res.end();
      });
  } else {
    res.writeHead(404);
    res.write('Not Found');
    res.end();
  }
});

// サーバーを起動
server.listen(port, () => {
  console.log('Client is ready');
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
