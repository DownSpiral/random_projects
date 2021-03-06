class Player
  attr_accessor :cur_pos, :name
  def initialize(name)
    @cur_pos = 0
    @name = name
  end
  def to_s
    "#{@name} (#{@cur_pos})"
  end
end

class ChutesAndLadders
  CHUTES_AND_LADDERS_HASH = {
    # Chutes
    16 => 6,
    48 => 26,
    49 => 11,
    56 => 53,
    62 => 19,
    64 => 60,
    87 => 24,
    93 => 73,
    95 => 75,
    98 => 78,

    # Ladders
    1 => 38,
    4 => 14,
    9 => 31,
    21 => 42,
    28 => 84,
    36 => 44,
    51 => 67,
    71 => 91,
    80 => 100
  }
  def initialize(player_names)
    @players = player_names.map { |n| Player.new(n) }
    @players.shuffle!
    @cur_player_index = 0
    @game_over = false
  end
  def make_next_move
    cur_player = @players[@cur_player_index]
    move_summary = ""
    name = cur_player.name
    spin_val = rand(1..6)
    move_summary += "#{cur_player} spins #{spin_val}."
    next_val = cur_player.cur_pos + spin_val
    if !(event_val = CHUTES_AND_LADDERS_HASH[next_val]).nil?
      if next_val < event_val
        move_summary += " #{name} goes up a ladder from #{next_val} to #{event_val}!"
      else
        move_summary += " #{name} slides down a chute from #{next_val} to #{event_val}!"
      end
      next_val = event_val
    else
      move_summary += " #{name} advances to #{next_val}!"
    end

    if next_val >= 100
      @game_over = true
      move_summary += " #{name} wins!"
    end

    cur_player.cur_pos = next_val
    @cur_player_index = (@cur_player_index + 1) % @players.length
    move_summary
  end
  def is_game_over?
    @game_over
  end
end

user_names = ARGV
game = ChutesAndLadders.new(user_names)
while !game.is_game_over?
  puts game.make_next_move
  sleep 1
end
