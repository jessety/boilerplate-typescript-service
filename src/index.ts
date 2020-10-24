import http from 'http';

const server = http.createServer((request, response) => {

  response.writeHead(200);

  response.end('ok');
});

const port = 8080;

server.listen(port, () => {
  console.log(`Now listening on port ${port}`);
});

server.on('error', (error) => console.error(error));
