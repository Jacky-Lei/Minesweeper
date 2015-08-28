require 'yaml'
require 'byebug'

# Break into multiple files
class MineSweeper
  attr_accessor :user, :board

  def initialize(user = User.new, board = Board.new)
    @user = user
    @board = board
    board.populate_grid
    debugger
  end

  def play

    #Refactor into helper methods
    until board.won?
      system("clear")
      board.display
      move = take_turn
      save if move[0] == "save"

      action, x, y = move[0], move[1].to_i, move[2].to_i

      # Refactor to case
      if action == "flag"
        board.flag_bomb(x, y)
      elsif action == "unflag"
        board.unflag_bomb(x, y)
      elsif action == "reveal"
        board.reveal(x, y)
      else
        puts "Invalid move."
      end
    end
    puts "You win!"
  end

  def take_turn
    user.take_turn
  end


  # Move some functionality to be private
  def save
    puts "Enter title:"
    name = gets.chomp
    File.open("#{name}", "w") do |f|
      f.puts self.to_yaml
    end
    Kernel.abort("Game saved!")
  end
end

class User

  def initialize
  end

  def take_turn
    puts "Enter your move: (flag/unflag/reveal/save, x, y)"
    gets.chomp.split(", ")
  end
end

class Board
  attr_accessor :grid
  attr_reader :number_bombs, :size


  def initialize(number_bombs = 10, size = 8)
    @grid = Array.new(size) { Array.new(size) }
    @number_bombs = number_bombs
    @size = size
  end

  # Add flagged_bomb
  def won?
    grid.flatten.all? do |tile|
      (tile.bomb && tile.flagged) || tile.state == :up
    end
  end

  def lose
    Kernel.abort("You lose!")
  end


  # Refactor
  def reveal(row,col)
    lose if self[row,col].bomb == true
    return if self[row,col].state == :up
    self[row,col].state = :up

    if neighbors(row, col).none? { |neighbor| self[*neighbor].bomb || self[*neighbor].flagged  }
      neighbors(row, col).each { |neighbor| reveal(*neighbor) }
    end
  end


  # Refactor to be more concise and readable
  def display
    grid.each_with_index do |row, ridx|
      display_rows = row.each_with_index.map do |col, cidx|
        tile_spot = self[ridx, cidx]

        # Allow tile to be responsible for it's representation (override to_s)
        if tile_spot.state == :down
          tile_spot.flagged ? :F : :*
        else
          # Refactor
          num_of_bombs = neighbors(ridx, cidx).inject(0) do |accum, neighbor|
            self[*neighbor].bomb ? accum + 1 : accum
          end
          num_of_bombs == 0 ? :_ : num_of_bombs
        end
      end
      puts "#{display_rows}"
    end
  end

  def [](row,col)
    @grid[row][col]
  end

  def []=(row, col, value)
    @grid[row][col] = value
  end

  def flag_bomb(row,col)
    self[row,col].flag_bomb
  end

  def unflag_bomb(row,col)
    self[row,col].unflag_bomb
  end

  def neighbors(row, col)
    positions = [
      [row - 1, col - 1],
      [row - 1, col],
      [row - 1, col +1],
      [row, col - 1],
      [row, col + 1],
      [row + 1, col - 1],
      [row + 1, col],
      [row + 1, col + 1]
    ]

  #  positions.select(&:on_board)
    positions.select do |tile|
      row, col = tile[0], tile[1]
      [row, col].all? { |pos| pos >= 0 && pos < size }
    end
  end

  #each_index
  def populate_grid
    bombs = bomb_order
    grid.each_with_index do |row, row_idx|
      row.each_with_index do |col, col_idx|
        grid[row_idx][col_idx] = Tile.new(bombs.pop)
      end
    end
  end

  # Renamed to be more semantically meaningful
  def bomb_order
    bombs = []
    number_bombs.times do
      bombs << true
    end
    (size * size - number_bombs).times do
      bombs << false
    end
    bombs.shuffle
  end
end

class Tile
  attr_accessor :state, :flagged
  attr_reader :bomb

  def initialize(bomb, state = :down)
    @bomb = bomb
    @state = state
    @flagged = false
  end

  def flag_bomb
    @flagged = true
  end

  def unflag_bomb
    @flagged = false
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV[0]
    YAML.load_file(ARGV.shift).play
  else
    game = MineSweeper.new
    game.play
  end
end
