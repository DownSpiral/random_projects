var http = require('http'),
    fs = require('fs'),
    // NEVER use a Sync function except at start-up!
    index = fs.readFileSync(__dirname + '/index.html');

// Send index.html to all requests
var app = http.createServer(function(req, res) {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end(index);
});

// Socket.io server listens to our app
var io = require('socket.io').listen(app);

var player_coords = {};

// Emit welcome message on connection
io.on('connection', function(socket) {
    // Use socket to communicate with this particular client only, sending it it's own id
    socket.emit('player_coords', player_coords);

    console.log("adding player: ", socket.id);
    socket.on('update_coords', function(coords) {
      player_coords[socket.id] = {
        x: coords.x,
        y: coords.y,
        name: coords.name,
        alive: coords.alive,
        ts: Date.now()
      };
      io.emit('player_coords', player_coords);
    });

    socket.on('disconnect', function(e) {
      delete player_coords[socket.id];
      io.emit('player_coords', player_coords);
    });
});

var prune_players = function() {
  Object.keys(player_coords).forEach(function(id) {
    var player = player_coords[id];
    if ((Date.now() - player.ts) > 6000) {
      console.log("pruning player: ", id);
      delete player_coords[id];
    }
  });
};
setInterval(prune_players.bind(this), 1000);

app.listen(3000);
