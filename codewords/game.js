var _ = require('underscore');
var nouns = require('nouns.js');

function game() {
  this.guessing_players = {};
  this.spy_master_players = {};
  this.words = this.generate_words();
  this.turn = _.sample(['red', 'blue']);
  this.card = this.genearte_card(this.turn);
  this.guess_state = this.generate_initial_guess_state();
  this.score = { red: 0, blue: 0 };
  this.is_over = false;
}

game.prototype.generate_words = function() {
  var words = _.sample(nouns, 25);
  return _.values(_.groupBy(words, function(v, i) { return i % 5; }));
}

game.prototype.generate_initial_guess_state = function() {
  var state = [];
  for (var i = 0; i < 5; i++) {
    var inner_state = [];
    for (var j = 0; j < 5; j++) {
      inner_state = inner_state.concat(0);
    }
    state = state.concat(inner_state);
  }
  return ;
}

game.prototype.generate_card = function(starting_color) {
  var red_count = 8 + (starting_color == 'red' ? 1 : 0);
  var blue_count = 8 + (starting_color == 'blue' ? 1 : 0);
  var card = ['assassin'];
  for (var i = 0; i < 7; i++) {
    card = card.concat('civ');
  }
  for (var i = 0; i < red_count; i++) {
    card = card.concat('red');
  }
  for (var i = 0; i < blue_count; i++) {
    card = card.concat('blue');
  }
  card = _.shuffle(card);
  return  _.values(_.groupBy(card, function(v, i) { return i % 5; }));
}

game.prototype.add_player = function(player) {
  var player_settings = {
    win_count: 0,
    death_count: 0,
    position: this.maze.start,
    id: player.id
  }
  this.players[player.id] = player_settings;
}

game.prototype.remove_player = function(id) {
  delete this.players[id];
}

game.prototype.handle_player_update = function(player_coord, id) {
  var player_data = this.players[id];
  var new_tile = this.maze.tile_at(player_coord.x, player_coord.y);
  var updates = {};
  //If we have a valid move
  if (!_.isNull(new_tile) && this.is_valid_move(player_data.position, new_tile)) {

    var has_died = this.is_tile_lethal(new_tile);

    //If the new move is the winning move
    if (!has_died && new_tile.same_coords(this.maze.end)) {
      //Update the win count of the winning player
      player_data.win_count++;
      this.players[id] = player_data;

      //Flag the game as being over
      this.is_over = true;
    } else { //Normal position update
      player_data.position = (has_died ? this.maze.start : new_tile);
      if (has_died) player_data.death_count++;
      this.players[id] = player_data;
      updates["player_data"] = player_data;
    }
  }
  return updates;
}

game.prototype.to_data_hash = function() {
  return {
    maze: this.maze,
    players: this.players,
    npcs: _.map(this.npcs, function(npc) { return npc.to_data_hash(); })
  }
}

game.prototype.reset_game = function() {
  //Regenerate the maze
  this.create_maze(this.maze.get_opposite_tile(this.maze.end))

  //Reset the player data
  _.each(this.players, function(player_data, player_id) {
    player_data.position = this.maze.start;
    this.players[player_id] = player_data;
  }, this);

  this.is_over = false;
}

exports.game = game;
