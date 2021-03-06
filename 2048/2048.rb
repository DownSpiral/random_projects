#!/usr/bin/env ruby

require "set"
require 'io/console'
require 'optparse'

class Tile
  attr_accessor :x, :y, :val
  VAL_TO_COLOR = {
    2 => 32, # green
    4 => 33, # brown
    8 => 36, # cyan
    16 => 35, # magenta
    32 => 34,
    64 => 31,
    128 => 31,
    256 => 31,
    512 => 31,
    1024 => 31,
  }
  def initialize(x, y, v)
    @x = x
    @y = y
    @val = v
  end
  def to_s
    (@val > 0 ? "\e[#{VAL_TO_COLOR[@val]}m#{@val.to_s.center(4)}\e[0m" : "    ").to_s
  end
end

class Board
  def initialize(width, height, initial_state=nil)
    @width = width
    @height = height
    @empty_tiles = Set.new()
    @board = Array.new(@height) { |y|
      Array.new(@width) { |x|
        v = initial_state.nil? ? 0 : (initial_state[y][x] || 0)
        t = Tile.new(x, y, v)
        @empty_tiles.add(t) unless v > 0
        t
      }
    }
  end
  def tiles
    @board
  end
  def random_empty_tile
    @empty_tiles.to_a.shuffle.first
  end
  def tile_at(x, y)
    @board[y][x]
  end
  def surrounding_tiles(x, y)
    tiles = []
    tiles << self.tile_at(x - 1, y) if x > 0
    tiles << self.tile_at(x + 1, y) if x < @width - 2
    tiles << self.tile_at(x, y - 1) if y > 0
    tiles << self.tile_at(x, y + 1) if y < @height - 2
    tiles
  end
  def set_tile_val(t, v)
    if v == 0
      @empty_tiles.add(t)
    else
      @empty_tiles.delete(t)
    end
    t.val = v
  end
  def slide_tiles(dir)
    pivot = dir == "up" || dir == "down"
    backwards = dir == "right" || dir == "down"
    value_of_merged_tiles = 0
    @board = @board.transpose if pivot
    @board.map! do |row|
      part = row.partition { |t| t.val != 0 }
      num_tiles = part[0]
      num_tiles.reverse! if backwards
      num_tiles.each_with_index do |t, i|
        break if i + 1 >= num_tiles.length
        next_t = num_tiles[i+1]
        if t.val != 0 && t.val == next_t.val
          value_of_merged_tiles += t.val * 2
          self.set_tile_val(t, t.val * 2)
          self.set_tile_val(next_t, 0)
        end
      end
      result = num_tiles.partition { |t| t.val != 0 }
      result += part[1]
      result.flatten!
      result.reverse! if backwards
      result
    end
    @board = @board.transpose if pivot
    value_of_merged_tiles
  end
  def is_full?
    @empty_tiles.empty?
  end
  def tile_values
    @board.map { |r| r.map(&:val) }
  end
  def to_s
    top_and_bottom = "-" * ((@width * 5) + 1) + "\n"
    row_sep = ("|" * (@width + 1)).split('').join("-" * 4) + "\n"
    middle = @board.map { |row|
      "|#{row.join("|")}|\n"
    }.join(row_sep)
    [top_and_bottom, middle, top_and_bottom].join("")
  end
end

class Game
  FOUR_PROBABILITY = 10 # 1/10 it will be a 4 instead of a 2
  VALID_INPUT = %w{ j k l i }
  INPUT_MAP = {
    "j" => "left",
    "k" => "down",
    "l" => "right",
    "i" => "up",
  }
  def initialize(w, h, initial_board=nil)
    @board = Board.new(w, h, initial_board)
    2.times { add_new_tile() } if initial_board.nil?
    @score = initial_board.nil? ? 0 : initial_board.flatten.reject { |v| v == 2 }.inject(0, :+)
  end
  def add_new_tile
    t = @board.random_empty_tile
    rand_val = rand(FOUR_PROBABILITY) == 0 ? 4 : 2
    @board.set_tile_val(t, rand_val)
  end
  def get_input
    char = nil
    while !VALID_INPUT.include?(char)
      char = STDIN.getch
      exit(1) if char == "\u0003"
    end
    INPUT_MAP[char]
  end
  def make_move(dir)
    old_values = @board.tile_values
    @score += @board.slide_tiles(dir)
    new_values = @board.tile_values
    self.add_new_tile() if old_values != new_values
  end
  def any_valid_merges?
    @board.tiles.each_with_index do |row, y|
      row.each_with_index do |t, x|
        return true if @board.surrounding_tiles(x, y).any? { |s_t| s_t.val == t.val }
      end
    end
    false
  end
  def has_won?
    @board.tiles.any? { |row| row.any? { |t| t.val >= 2048 } }
  end
  def has_lost?
    @board.is_full? && !self.any_valid_merges?
  end
  def is_over?
    self.has_lost? || self.has_won?
  end
  def to_s
    @board.to_s + "Score: #{@score.to_s}\n"
  end
  def self.parse_game_from_str(s)
    rows = s.split("\n").reject { |l| l.include?("-") }
    rows.map { |r| r.split("|")[1..-1].map(&:strip).map(&:to_i) }.transpose
  end
end

options = {
  width: 4,
  height: 4,
}
OptionParser.new do |opts|
  BOARD_EXAMPLE = <<-EOF
--------------------------
| 8  | 4  | 4  |    |    |
|----|----|----|----|----|
| 8  |128 | 16 | 64 | 2  |
|----|----|----|----|----|
| 64 | 32 |    |    |    |
|----|----|----|----|----|
| 8  | 16 |    |    |    |
|----|----|----|----|----|
|1024|    |    | 2  |    |
--------------------------
EOF
  opts.banner = "Usage: ./2048.rb [options]"
  opts.on("-d[DIMENSIONS]", "--dimensions=[DIMENSIONS]", "Specify board 'WIDTHxHEIGHT'. Default is '4x4'") do |d|
    puts d
    arr = d.split("x").map(&:to_i)
    options[:width] = arr[0]
    options[:height] = arr[1]
  end
  opts.on("-p", "--paste", "Paste a board to initialize the game in that state") do |h|
    puts "Paste the board and then enter a new line:"
    board_str = ""
    while (text = gets) != "\n"
      board_str << text
    end
    options[:board_array] = Game.parse_game_from_str(board_str)
  end
  opts.on("-h", "--help", "Prints this help") do |h|
    puts opts
    exit
  end
end.parse!

if options[:board_array]
  options[:width] = options[:board_array].first.length
  options[:height] = options[:board_array].length
end

game = Game.new(options[:width], options[:height], options[:board_array])

system('clear')
puts game
puts "Use j,k,l,i to move.\nCtrl-C to exit.\nCombine like numbers to make 2048!\nGood luck!"
while not game.is_over?
  input = game.get_input
  game.make_move(input)
  system('clear')
  puts game
end
puts (game.has_won? ? "You win!" : "Oh no, there are no valid moves! Try again!")
