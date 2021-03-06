def print_times_table(n)
  puts
  puts "Kimmy's Times Table!"
  puts ""
  (1..n).to_a.map { |x|
    str = ""
    (1..n).to_a.map { |y| str += sprintf("%4d ", x * y) }
    puts str
  }
end

#print_times_table(12)

class GuessingGame
  BURNING_THRESHHOLD_PERCENT = 1
  HOT_THRESHHOLD_PERCENT = 5
  WARM_THRESHHOLD_PERCENT = 20
  COLD_THRESHHOLD_PERCENT = 40
  FREEZING_THRESHHOLD_PERCENT = 60

  def initialize(player_names, max_num)
    @max_num = max_num
    @players = player_names
    @num_players = @players.length

    @player_num = rand(@num_players)
    @answer = rand(@max_num) + 1
    @game_over = false
    @player = @players[@player_num]
  end

  def start
    puts "Can you guess the number I am thinking of first? It is between 1 and #{@max_num}\n\n"
    while !@game_over
      puts "--------------------------------------------"
      guess = self.get_guess
      if guess == @answer
        puts "#{@player} wins! The correct answer was #{@answer}\n\n"
        @game_over = true
      else
        adj = self.get_adjective(guess)
        puts "Number #{guess} is #{adj}!\n\n"
        self.next_player
        sleep 2
      end
    end
  end

  def next_player
    @player_num = (@player_num + 1) % @num_players
    @player = @players[@player_num]
  end

  def get_guess
    print "It's #{@player}'s turn to guess: "
    guess = nil
    while guess.nil?
      input = gets.chomp
      guess = input.to_i
      if guess == 0 || guess > @max_num
        print "\n'#{input}' isn't between 1 and #{@max_num}! Try again #{@player}: "
        guess = nil
      end
    end
    guess
  end

  def get_adjective(guess)
    case ((@answer - guess).abs * 100 / @max_num)
    when 0..BURNING_THRESHHOLD_PERCENT
      "burning"
    when BURNING_THRESHHOLD_PERCENT..HOT_THRESHHOLD_PERCENT
      "hot"
    when HOT_THRESHHOLD_PERCENT..WARM_THRESHHOLD_PERCENT
      "warm"
    when WARM_THRESHHOLD_PERCENT..COLD_THRESHHOLD_PERCENT
      "cold"
    when COLD_THRESHHOLD_PERCENT..FREEZING_THRESHHOLD_PERCENT
      "freezing"
    else
      "frozen"
    end
  end
end

players = ["Kimmy", "Eric"]
playing = true
while playing
  game = GuessingGame.new(players, 100)
  game.start
  puts "Would you like to play again? (yes or no)"
  input = gets.chomp
  if input.downcase == "no"
    playing = false
    puts "Thanks for playing! Come back again soon!"
  end
end
