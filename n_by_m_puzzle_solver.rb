VALID_FACES = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
VALID_BUTTS = %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
INVERSE = Hash[VALID_FACES.zip(VALID_BUTTS)].merge(Hash[VALID_BUTTS.zip(VALID_FACES)])
N = 0
E = 1
S = 2
W = 3

n = ARGV[0].to_i
m = ARGV[1].to_i
k = ARGV[2].to_i

puts "generating #{n} x #{m} board with #{k} pairs"

# output tiles: NESW NESW
def generate(n, m, k)
  board = Array.new(m) { Array.new(n) }
  return nil if k > VALID_FACES.length
  valid_keys = VALID_FACES[0...k] + VALID_BUTTS[0...k]
  n.times do |i|
    m.times do |j|
      north = board[i][j-1] rescue nil
      east = board[i+1][j] rescue nil
      south = board[i][j+1] rescue nil
      west = board[i-1][j] rescue nil

      str = "----"
      str[W] = INVERSE[west[E]] unless i == 0 || west.nil?
      str[E] = INVERSE[east[W]] unless i == n - 1 || east.nil?
      str[N] = INVERSE[north[S]] unless j == 0 || north.nil?
      str[S] = INVERSE[south[N]] unless j == m - 1 || south.nil?

      tile = str.split("").map { |c| c == "-" ? valid_keys.sample : c }.join("")
      board[i][j] = tile
    end
  end
  board
end

def rotate_tile_n(t, n)
  r = n % t.length
  t[r..-1] + t[0...r]
end

def randomize_tile(t)
  r = rand(t.length)
  rotate_tile_n(t, r)
end

def randomize(board)
  board.flatten.shuffle.map { |t| randomize_tile(t) }
end

def board_to_string(board)
  board.transpose.map { |row|
    row.map { |t|
      [" #{t[0]} ", "#{t[3]} #{t[1]}", " #{t[2]} "]
    }.transpose.map { |row| row.join }
  }.join("\n")
end

def tile_perms_of_tiles(tiles)
  tiles.map { |t| (0...t.length).map { |i| rotate_tile_n(t, i) } }
end

def tile_match_tmpl?(tile, tmpl)
  tile.split("").each_with_index.all? { |t, i| tmpl[i] == "-" || tmpl[i] == t }
end

def get_template_str(board, i, j)
  north = board[i][j-1] rescue nil
  east = board[i+1][j] rescue nil
  south = board[i][j+1] rescue nil
  west = board[i-1][j] rescue nil

  str = "----"
  str[W] = INVERSE[west[E]] unless i == 0 || west.nil?
  str[E] = INVERSE[east[W]] unless i == board.length - 1 || east.nil?
  str[N] = INVERSE[north[S]] unless j == 0 || north.nil?
  str[S] = INVERSE[south[N]] unless j == board.length - 1 || south.nil? # fix board.length
  str
end

def get_next_peice(tmpl, perms, last_p_index, last_t_index)
  perms.each_with_index { |p, p_index|
    p && p.each_with_index { |t, t_index|
      if (last_p_index.nil? || p_index > last_p_index || (p_index == last_p_index && t_index > last_t_index)) && tile_match_tmpl?(t, tmpl)
        return [p_index, t_index]
      end
    }
  }
  [nil, nil]
end

def validate_remaining(stats)
  # Ensure there are at least enough pairings left given the active faces
  stats[:needed_face_counts].all? { |char, count|
    stats[:rem_tiles_face_counts][char] >= count
  }
end

def get_tiles_face_counts(tiles)
  Hash[tiles.map { |t| t.split("") }.flatten.group_by { |c| c }.map { |c, arr| [c, arr.length] }]
end

def solve(n, m, k, tiles)
  board = Array.new(m) { Array.new(n) }
  perms = tile_perms_of_tiles(tiles)
  perms_in_use = Array.new(tiles.length)
  solution_size = n * m
  stats = {
    needed_face_count: {},
    rem_tiles_face_counts: get_tiles_face_counts(tiles),
  }

  cur_i = 0
  cur_j = 0
  solution = []
  last_p_index = nil
  last_t_index = nil
  tries = 0
  while solution.length != solution_size
    tmpl = get_template_str(board, cur_i, cur_j)
    p_index, t_index = get_next_peice(tmpl, perms, last_p_index, last_t_index)
    if !p_index.nil? && !t_index.nil?
      tries += 1
      perm = perms[p_index]
      board[cur_i][cur_j] = perm[t_index]
      solution << [p_index, t_index]
      perms_in_use[p_index] = perm
      perms[p_index] = nil
      cur_i += 1
      if cur_i >= n
        cur_i = 0
        cur_j += 1
      end
      last_p_index = nil
      last_t_index = nil
    else
      last_p_index, last_t_index = solution.pop
      perms[last_p_index] = perms_in_use[last_p_index]
      perms_in_use[last_p_index] = nil
      cur_i -= 1
      if cur_i < 0
        cur_i = n - 1
        cur_j -= 1
      end
      board[cur_i][cur_j] = nil
    end
  end
  puts tries
  board
end

 board = generate(n, m, k)
 puts "---- generated board ----"
 puts board_to_string(board)
 puts
# puts

tiles = randomize(board) # 
puts "---- randomized tiles ----"
puts tiles.join(" ")
puts

solved_board = solve(n, m, k, tiles)
puts "---- solved board ----"
puts board_to_string(solved_board)
