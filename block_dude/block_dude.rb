class Player
  attr_accessor :position

  def initialize(tile)
    @position = tile
  end

  def move_to(new_tile)
    @position.val = Tile::EMPTY
    new_tile.position.val = Tile::PLAYER
    @position = new_tile
  end
end

class Tile
  attr_accessor :x
  attr_accessor :y
  attr_accessor :val

  EMPTY = ' '
  WALL = 'W'
  PLAYER = 'P'
  BLOCK = 'B'

  def initialize(x, y, val)
    @x = x
    @y = y
    @val = val
  end

  def is?(type)
    @val == type
  end
end

class Grid
  def initialize(data)
    @width = data.first.size
    @height = data.size
    @grid = []
    (0...@height).each do |y|
      @grid[y] = Array.new()
      (0...@width).each do |x|
        @grid[y][x] = Tile.new(x, y, data[y][x])
      end
    end
  end

  def at(x, y)
    @grid[y][x] rescue nil
  end

  def next_tile_from_dir(dir, tile)
    if dir == LEFT
      at(tile.x - 1, tile.y)
    elsif dir == RIGHT
      at(tile.x + 1, tile.y)
    elsif dir == UP
      at(tile.x, tile.y - 1)
    elsif dir == DOWN
      at(tile.x, tile.y + 1)
    else
      nil
    end
  end

  def each
    @grid.each do |row|
      row.each do |t|
        yield t
      end
    end
  end

  def print
    @grid.each do |row|
      puts row.map{ |t| t.val }.join
    end
  end
end

class Game
  LEFT = "left"
  RIGHT = "right"
  UP = "up"
  DOWN = "down"

  def initialize(filename)
    data = CSV.parse(filename)
    @map = Grid.new(data)
    player_start = nil
    @map.each do |t|
      player_start = t if t.is?(Tile::PLAYER)
    end
    if player_start.nil?
      puts "Failed to find player start! Exiting."
      exit
    else
      @player = Player.new(player_start)
    end
  end

  def move_dir(dir)
    next_tile = @map.next_tile_from_dir(dir, @player.position)
    return if next_tile.nil?

    if next_tile.is?(Tile::BLOCK)
      block_target = @map.next_tile_from_dir(dir, next_tile)
      if block_target && block_target.is?(Tile::EMPTY)
        next_tile.val = Tile::EMPTY
        block_target = Tile::BLOCK
      end
    elsif next_tile.is?(Tile::EMPTY)
      @player.move_to(next_tile)
    end
  end

end

g = Grid.new(["123", "456", "789"])
g.print
