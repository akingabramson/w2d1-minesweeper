class Square
  attr_accessor :adjacent_bombs, :revealed, :flagged, :bomb

  def initialize
    @revealed = false
    @bomb = false
    @adjacent_bombs = 0
    @flagged = false
  end

end

class Game
  attr_accessor :board, :bomblist

  def initialize
    @bomblist = []
  end

  def make_board(rows)
    @board = Array.new(rows) {Array.new(rows) {Square.new} }
    assign_bombs
    assign_fringes
  end

  def assign_bombs
    until @bomblist.count == 10
      xbomb = rand(@board.length)
      ybomb = rand(@board.length)
      unless @bomblist.include?([xbomb, ybomb])
        @board[xbomb][ybomb].bomb = true
        @bomblist << [xbomb, ybomb]
      end
    end
  end

# Helper method for assign_fringes. DO NOT CALL
  def generate_fringes
    adjacents = []
    fringes = []

    @bomblist.each do |bomb|
      x = bomb[0]
      y = bomb[1]

      adjacents += [
        [x+1,y],
        [x+1,y+1],
        [x+1,y-1],
        [x,y+1],
        [x,y-1],
        [x-1,y+1],
        [x-1,y],
        [x-1,y-1]
      ]


      fringes = adjacents.select do |location|
        !@bomblist.include?(location) && on_board?(location)
      end

    end

    fringes
  end

  def on_board?(location)
    (0..@board.length-1).include?(location[0]) && (0..@board.length-1).include?(location[1])
  end

  def assign_fringes
    fringes = generate_fringes

    fringes.each do |coordinates|
      @board[coordinates[0]][coordinates[1]].adjacent_bombs += 1
    end
  end

  def print_board
    @board.each do |row|
      print_array = []
      row.each do |spot|
        if spot.revealed == false
          print_array << "*"
        elsif spot.bomb == true
          print_array << "B"
        else
          print_array << spot.adjacent_bombs.to_s
        end
      end
      puts print_array.inspect
    end
  end

  def get_input
    move = nil
    location = []
    while true
      puts "Player, make your choice. [R]eveal or [F]lag (x,y)."
      #no invalids, misspellings or off board

      choice = gets.chomp.split(" ")
      move = choice[0].downcase
      location = choice[1].split(",")
      location.map!(&:to_i)
      if on_board?(location) == false || !["r", "f"].include?(move)
        puts "Invalid choice\n\n"
      else
        break
      end
    end
    [move, location]
  end

  def run_game

  end

  def apply_move(move)

  end

  def game_over?
    @board.each do |row|
      row.each do |spot|
        return true if spot.bomb && spot.revealed
        return false if !spot.bomb && !spot.revealed
      end
    end

    @bomblist.each do |location|
      if @board[location[0]][location[1]].flagged == false
        return false
      end
    end
    true
  end


end

a = Game.new
a.make_board(9)
a.print_board
p a.game_over?