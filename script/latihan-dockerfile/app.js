const http = require('http');
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Halo dari container!\n');
}).listen(3000);
console.log('Server jalan di port 3000');
