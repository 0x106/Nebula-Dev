var app = require('express')();
var server = require('http').Server(app);
var io = require('socket.io')(server);

var iosID = ""
var webID = ""

server.listen(3000, function() {
  console.log("Nebula server listening on port: 3000");
});

app.set('view engine', 'hbs');

app.get('/', function (req, res) {
  res.sendfile(__dirname + '/index.html');
});

io.on('connection', function (socket) {

  console.log(`Nebula received connection from socket: ${socket.id}`);

  socket.on('ios-client', function(data) {
    socket.emit('nebula', socket.id);
    iosID = socket.id
  });

  socket.on('web-client', function(data) {
    socket.emit('nebula', socket.id);
    webID = socket.id
  });

  socket.on('data', function(data) {
    if (socket.id === iosID) {
      io.to(webID).emit('data', {"data": data});
    }
  });

  socket.on('image', function(data) {
    console.log(data["imagename"]);
  });
});
