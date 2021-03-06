require 'set'
require 'socket'
require 'json'
require 'optparse'
require 'io/console'

class Ship
attr_accessor :type, :x, :y, :dir, :being_placed
  SHIP_SIZES = {
    'carrier' => 5,
    'battleship' => 4,
    'cruiser' => 3,
    'submarine' => 3,
    'destroyer' => 2
  }
  SHIP_CHARS = {
    'carrier' => 'A',
    'battleship' => 'B',
    'cruiser' => 'C',
    'submarine' => 'S',
    'destroyer' => 'D'
  }
  SHIP_COLORS = {
    'undamaged' => 32,
    'damaged' => 33,
    'sunk' => 35,
    'placing' => 36,
  }

  def initialize(type, location, dir, being_placed=false)
    @type = type
    @x = location[0]
    @y = location[1]
    @dir = dir
    @hp = SHIP_SIZES[@type]
    @being_placed = being_placed
  end

  def set_coords(x, y)
    @x = x
    @y = y
  end

  def size
    SHIP_SIZES[@type]
  end

  def hit
    @hp -= 1
  end

  def is_damaged?
    @hp > 0 && @hp < SHIP_SIZES[@type]
  end

  def is_sunk?
    @hp <= 0
  end

  def is_placing?
    @being_placed
  end

  def coord_pairs
    if @dir == "right"
      (@x...@x+self.size).map { |x| [x, @y].join("-") }
    elsif @dir == "down"
      (@y...@y+self.size).map { |y| [@x, y].join("-") }
    end
  end

  def as_hash
    {
      type: @type,
      coord: [@x, @y],
      dir: @dir,
    }
  end

  def status
    if self.is_sunk?
      "sunk"
    elsif self.is_damaged?
      "damaged"
    elsif self.is_placing?
      "placing"
    else
      "undamaged"
    end
  end

  def to_s
    "\e[#{SHIP_COLORS[self.status]}m#{SHIP_CHARS[@type]}\e[0m"
  end
end

class BattleshipPlacement
  SHIPS = [
    'carrier',
    'battleship',
    'cruiser',
    'submarine',
    'destroyer'
  ]

  def initialize(width, height)
    @width = width
    @height = height
    @ship_data = []
    @board_data = {}
    @active_ship = nil
  end

  def place_ships_randomly!
    SHIPS.each do |type|
      loop do
        dir = ['right', 'down'].shuffle.first
        l_max = (dir == 'down' ? @width : @width - Ship::SHIP_SIZES[type])
        h_max = (dir == 'right' ? @height : @height - Ship::SHIP_SIZES[type])
        break if place_ship(Ship.new(type, [rand(l_max), rand(h_max)], dir))
      end
    end
  end

  INPUT_MAP = {
    "j" => "left",
    "k" => "down",
    "l" => "right",
    "i" => "up",
    "r" => "rotate",
    "\r" => "enter",
  }
  def get_input
    char = nil
    while !INPUT_MAP.keys.include?(char)
      char = STDIN.getch
      exit(1) if char == "\u0003"
    end
    INPUT_MAP[char]
  end

  def move_active_ship(dir)
    new_x = @active_ship.x + (dir == "right" ? 1 : (dir == "left" ? -1 : 0))
    new_y = @active_ship.y + (dir == "down" ? 1 : (dir == "up" ? -1 : 0))
    x_max = (@active_ship.dir == 'down' ? @width - 1 : @width - @active_ship.size)
    y_max = (@active_ship.dir == 'right' ? @height - 1 : @height - @active_ship.size)
    if new_x >= 0 && new_x <= x_max && new_y >= 0 && new_y <= y_max
      @active_ship.set_coords(new_x, new_y)
    end
  end
  def rotate_active_ship(dir)
    if dir == "right" || dir == "down"
      tail_x = (dir == 'down' ? @active_ship.x : @active_ship.x + @active_ship.size)
      tail_y = (dir == 'right' ? @active_ship.y : @active_ship.y + @active_ship.size)
      if tail_x >= 0 && tail_x <= @width && tail_y >= 0 && tail_y <= @height
        @active_ship.dir = dir
      end
    end
  end

  DIRECTIONS = %w{ left right down up }
  INSTRUCTIONS = "Use j,k,l,i to move the ship.\nUse r to rotate it.\nPress enter to place it."
  def run_player_setup
    SHIPS.each do |type|
      @active_ship = Ship.new(type, [0, 0], "right", true)
      error = ""
      loop do
        system('clear')
        puts self
        puts INSTRUCTIONS
        puts error
        input = self.get_input()
        if DIRECTIONS.include?(input)
          self.move_active_ship(input)
          error = ""
        elsif input == "rotate"
          self.rotate_active_ship(@active_ship.dir == "right" ? "down" : "right")
          error = ""
        elsif input == "enter"
          break if self.place_ship(@active_ship)
          error = "Intersecting another ship. Please move it and try again."
        end
      end
    end
  end

  # returns true if successful, false otherwise
  def place_ship(ship)
    # Check for intersection with existings ships
    coords = ship.coord_pairs
    if !coords.any? { |c| @board_data[c] }
      ship.being_placed = false
      @ship_data << ship
      coords.each { |c| @board_data[c] = ship }
      true
    else
      false
    end
  end

  def get_ships
    @ship_data
  end

  def as_hash
    @ship_data.map(&:as_hash)
  end

  def to_s
    titles = "Ship placement".center((@width * 4) + 1) + "\n"
    titles_spacer = "#{' '*((@width * 4) + 1)}\n"
    top_nums = " #{(1..10).map { |i| i.to_s.center(3) }.join(" ")} \n"
    top_and_bot_boarder = "-" * ((@width * 4) + 1) + "\n"
    board_sep = ('|' * (@width + 1)).split('').join("-" * 3) + "\n"
    active_ship_set = Set.new(@active_ship.coord_pairs)
    middle = (0...@height).map { |y|
      ship_row = (0...@width).map { |x|
        cur_coord = "#{x}-#{y}"
        ship = @board_data[cur_coord]
        if active_ship_set.include?(cur_coord)
          ship = (ship.nil? ? @active_ship : "\e[31mX\e[0m")
        end
        " #{ship.nil? ? " " : ship} "
      }.join("|")
      "|#{ship_row}| #{(65 + y).chr}\n"
    }.join(board_sep)
    [titles, titles_spacer, top_nums, top_and_bot_boarder, middle, top_and_bot_boarder].join
  end
end

class Player
  attr_accessor :guesses, :ships, :board_info, :id

  def initialize(id, ships)
    @id = id
    @ships = ships
    @guesses = {}
    @board_info = @ships.each_with_object({}) { |ship, hash|
      ship.coord_pairs.each { |c| hash[c] = ship }
    }
  end

  def is_dead?
    @ships.all? { |s| s.is_sunk? }
  end
end

class Game
  # Player one is the active player of the game
  # Player two is the opponent
  def initialize(player_ships, width, height, starting_player)
    @width = width
    @height = height
    @players = player_ships.map.with_index { |ships, i| Player.new(i, ships) }
    @current_player_index = starting_player
  end

  def active_player
    @players.first
  end

  def is_active_players_turn?
    @current_player_index == 0
  end

  def opponent
    @players.last
  end

  def current_player
    @players[@current_player_index]
  end

  def next_player
    @players[(@current_player_index + 1) % @players.length]
  end

  def prev_player
    @players[@current_player_index - 1]
  end

  def parse_guess(guess)
    if !(m = /\A([A-J])(\d+)\z/.match(guess)).nil?
      letter = m[1]
      letter_as_num = letter.ord - 65
      num = m[2].to_i
      if num > 0 && num <= @width && letter_as_num >= 0 && letter_as_num < @height
        [num - 1, letter_as_num]
      else
        nil
      end
    else
      nil
    end
  end

  def move_already_made?(move)
    !self.current_player.guesses[move.join("-")].nil?
  end

  def make_move(move)
    enemy_ship = self.next_player.board_info[move.join("-")]
    result = if enemy_ship.nil?
      self.current_player.guesses[move.join("-")] = "O"
      "Miss!"
    else
      enemy_ship.hit()
      if enemy_ship.is_sunk?
        self.current_player.guesses[move.join("-")] = "S"
        "Hit and sunk!"
      else
        self.current_player.guesses[move.join("-")] = "X"
        "Hit!"
      end
    end
    @current_player_index = (@current_player_index + 1 ) % @players.length
    result
  end

  def alive_players
    @players.reject { |p| p.is_dead? }
  end

  def is_over?
    self.alive_players.length == 1
  end

  def self.move_arr_to_s(move)
    (65 + move[1]).chr + (move[0] + 1).to_s
  end

  GUESS_COLORS = {
    'X' => 31,
    'S' => 35,
  }
  def to_s
    titles = ["My ships".center((@width * 4) + 1), "Past guesses".center((@width * 4) + 1)].join("    |  ") + "\n"
    titles_spacer = "#{' '*((@width * 4) + 1)}    |  #{' '*((@width * 4) + 1)}\n"
    top_nums_board = " #{(1..@width).map { |i| i.to_s.center(3) }.join(" ")} "
    top_nums = [top_nums_board, top_nums_board].join("    |  ") + "\n"
    top_and_bot_boarder_board = "-" * ((@width * 4) + 1)
    top_and_bot_boarder = [top_and_bot_boarder_board, top_and_bot_boarder_board].join("    |  ") + "\n"
    board_sep = ('|' * (@width + 1)).split('').join("-" * 3)
    row_sep = [board_sep, board_sep].join("    |  ") + "\n"
    middle = (0...@height).map { |y|
      ship_row = (0...@width).map { |x|
        coord = "#{x}-#{y}"
        opponent_guess = self.opponent.guesses[coord]
        opponent_guess_char = "\e[#{GUESS_COLORS[opponent_guess]}m#{opponent_guess}\e[0m"
        ship_char = ((ship = self.active_player.board_info[coord]) ? ship.to_s : " ")
        char_for_coord = (opponent_guess ? opponent_guess_char : ship_char)
        " #{char_for_coord} "
      }.join("|")
      guess_row = (0...@width).map { |x|
        coord = "#{x}-#{y}"
        guess = self.active_player.guesses[coord]
        guess_char = "\e[#{GUESS_COLORS[guess]}m#{guess}\e[0m"
        " #{(guess ? guess_char : " ")} "
      }.join("|")
      "|#{ship_row}| #{(65 + y).chr}  |  |#{guess_row}| #{(65 + y).chr}\n"
    }.join(row_sep)
    [titles, titles_spacer, top_nums, top_and_bot_boarder, middle, top_and_bot_boarder].join
  end
end

options = {
  width: 10,
  height: 10,
  is_server: false,
  port: 2000,
  server_ip: "localhost",
  example: false,
}
OptionParser.new do |opts|
  opts.banner = "Usage: ./battleships.rb [options]"

  opts.on("-d[DIMENSIONS]", "--dimensions=[DIMENSIONS]", "Specify board 'WIDTHxHEIGHT'. Default is '10x10'.") do |d|
    puts d
    arr = d.split("x").map(&:to_i)
    options[:width] = arr[0]
    options[:height] = arr[1]
  end

  opts.on("-s", "--server", "Set to launch the server") do |s|
    options[:is_server] = true
  end

  opts.on("-p[PORT]", "--port=[PORT]", "Set the port to launch on. Default is 2000.") do |p|
    options[:port] = p.to_i
  end

  opts.on("-i[IP]", "--ip=[IP]", "Set the ip to connect to. Default is localhost.") do |ip|
    options[:server_ip] = ip
  end

  opts.on("-e", "--example", "Set to play an example game.") do |s|
    options[:example] = true
  end

  opts.on("-h", "--help", "Prints this help") do |h|
    puts opts
    exit
  end
end.parse!

def make_and_do_placement(width, height)
  b = BattleshipPlacement.new(width, height)
  print "Do manual placement? ([Y]/N) "
  yes_no = STDIN.gets.chomp.downcase
  if yes_no.include?("y") || yes_no == ""
    b.run_player_setup()
  else
    b.place_ships_randomly!
  end
  b
end

if options[:example]
  b1 = make_and_do_placement(options[:width], options[:height])
  b2 = BattleshipPlacement.new(options[:width], options[:height])
  b2.place_ships_randomly!
  game = Game.new([b1.get_ships, b2.get_ships], options[:width], options[:height], 0)
  system('clear')
  puts game
  all_guesses = []
  (0...10).each { |x| (0...10).each { |y| all_guesses << [x, y] } }
  i = 0

  while !game.is_over?
    print "Next guess: "
    # guess = STDIN.gets.chomp
    # move = game.parse_guess(guess.upcase)
    move = all_guesses[i]

    # make player one move
    if move.nil?
      puts "Invalid guess. Move must be a letter followed immediately by a number (e.g. A7)"
    elsif game.move_already_made?(move)
      puts "That guess has already been made. Try again"
    else
      result = game.make_move(move)
      system('clear')
      puts game
      puts result
    end

    # make player two move
    if move.nil?
      puts "Invalid guess. Move must be a letter followed immediately by a number (e.g. A7)"
    elsif game.move_already_made?(move)
      puts "That guess has already been made. Try again"
    else
      result = game.make_move(move)
      system('clear')
      puts game
      puts result
    end
    i += 1
  end
  puts (game.alive_players.first.id == 0 ? "Last ship sunk! You win!" : "All of your ships were sunk. Time to have the feel bads.")

  exit
end

game = nil
socket = nil
if options[:is_server]
  puts "Starting server on port #{options[:port]}"
  server = TCPServer.new options[:port]

  puts "Waiting for another player"
  socket = server.accept    # Wait for a client to connect

  puts "Player connected"
  puts "Sendings game details"
  starting_player = rand(1)
  socket.puts({
    "width" => options[:width],
    "height" => options[:height],
    "starting_player" => ((starting_player + 1) % 2)
  }.to_json)

  puts "Starting ship configuration."
  b = make_and_do_placement(options[:width], options[:height])

  puts "Sendings ship details"
  socket.puts({
    "ships" => b.as_hash,
  }.to_json)

  puts "Getting client ships"
  client_ship_hashes = JSON.parse(socket.gets.chomp)
  client_ships = client_ship_hashes.map { |s| Ship.new(s["type"], s["coord"], s["dir"]) }

  puts "Got client ships"
  game = Game.new(
    [b.get_ships, client_ships],
    options[:width],
    options[:height],
    starting_player
  )
else
  puts "Connecting on #{options[:server_ip]}:#{options[:port]}"
  while socket.nil?
    socket = TCPSocket.new options[:server_ip], options[:port] rescue nil
    break unless socket.nil?
    puts "Server not up. Waiting 5 seconds and then trying again."
    sleep 5
  end

  puts "Connected to server. Getting game details."
  game_details = JSON.parse(socket.gets.chomp)

  puts "Got game details from server."
  puts "Starting ship configuration."
  b = make_and_do_placement(game_details["width"], game_details["height"])

  puts "Done with ship configuration."
  puts "Getting ship data from server."
  game_details = game_details.merge(JSON.parse(socket.gets.chomp))
  server_ships = game_details["ships"].map { |s| Ship.new(s["type"], s["coord"], s["dir"]) }

  puts "Got ship details from server."
  puts "Sending ships to server"
  socket.puts(b.as_hash.to_json)
  game = Game.new(
    [b.get_ships, server_ships],
    game_details["width"],
    game_details["height"],
    game_details["starting_player"]
  )
end

puts "Starting game"
system('clear')
puts game
while !game.is_over?
  move = nil
  if game.is_active_players_turn?
    # Current players move, so get input
    loop do
      print "Next guess: "
      guess = STDIN.gets.chomp
      move = game.parse_guess(guess.upcase)
      if move.nil?
        puts "Invalid guess. Move must be a letter followed immediately by a number (e.g. A7)"
      elsif game.move_already_made?(move)
        puts "That guess has already been made. Try again"
      else
        puts "Sending move to server"
        socket.puts(move.to_json)
        break
      end
    end
  else
    # Other players move, so wait for input
    puts "Waiting for the other players move"
    move = JSON.parse(socket.gets.chomp)
    puts "Got move: #{Game.move_arr_to_s(move)}"
  end

  result = game.make_move(move)
  system('clear')
  puts game
  puts "#{Game.move_arr_to_s(move)} - #{result}"
end

puts (game.alive_players.first.id == 0 ? "Last ship sunk! You win!" : "All of your ships were sunk. Time to have the feel bads.")
socket.close
