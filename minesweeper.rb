require 'yaml'
require 'json'

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
  attr_accessor :board, :bomblist, :start_time, :end_time, :total_time

  def initialize
    @bomblist = []
    @total_time = 0
  end

  def make_board(rows)
    @board = Array.new(rows) {Array.new(rows) {Square.new} }
    if rows == 9
      assign_bombs(10)
    else
      assign_bombs(40)
    end
    assign_fringes
    nil
  end

  def assign_bombs(total)
    until @bomblist.count == total
      xbomb = rand(@board.length)
      ybomb = rand(@board.length)
      unless @bomblist.include?([xbomb, ybomb])
        @board[xbomb][ybomb].bomb = true
        @bomblist << [xbomb, ybomb]
      end
    end
  end

  def generate_adjacents(location)
    adjacents = []
    fringes = []

    x = location[0]
    y = location[1]

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

    fringes
  end

  def on_board?(location)
    (0..@board.length-1).include?(location[0]) && (0..@board.length-1).include?(location[1])
  end

  def assign_fringes
    fringes = []
    @bomblist.each do |bomb|
      fringes += generate_adjacents(bomb)
    end

    fringes.each do |coordinates|
      @board[coordinates[0]][coordinates[1]].adjacent_bombs += 1
    end
  end

  def print_board
    @board.each do |row|
      print_array = []
      row.each do |spot|
        if spot.revealed == false
          if spot.flagged == true
            print_array << "F"
          else
            print_array << "*"
          end
        elsif spot.bomb == true
          print_array << "B"
        else
          print_array << spot.adjacent_bombs.to_s
        end
      end
      puts print_array.inspect
    end
    nil
  end

  def get_input
    move = nil
    location = []
    while true
      puts "Player, make your choice. [R]eveal or [F]lag (x,y). || [S]ave to exit."
      #no invalids, misspellings or off board
      save_catch = gets.chomp
      return "s" if save_catch == "s"

      choice = save_catch.chomp.split(" ")
      move = choice[0].downcase
      location = choice[1].split(",")
      location.map!(&:to_i)
      if on_board?(location) == false || !["r", "f"].include?(move)
        puts "Invalid Choice: Bad input. \n\n"
      elsif @board[location[0]][location[1]].flagged && move == "r" || @board[location[0]][location[1]].revealed && move == "f" || @board[location[0]][location[1]].revealed && move == "r"
        puts "Invalid Choice: Spot has already been flagged or revealed\n\n"
      else
        break
      end
    end
    [move, location]
  end

  def apply_move(input)
    move = input[0]
    location = input[1]

    case move
      when "r"
        @board[location[0]][location[1]].revealed = true
        if @board[location[0]][location[1]].bomb
          return nil
        end
        reveal_adjacents(location)
      when "f"
        @board[location[0]][location[1]].flagged = !@board[location[0]][location[1]].flagged
    end
  end

  def reveal_adjacents(location)
    #queue starts with selected square
    queue = [location]
    history = []

    until queue.empty?
      coord = queue.shift
      history << coord
      if @board[coord[0]][coord[1]].adjacent_bombs == 0
        candidates = generate_adjacents(coord)

        candidates = candidates.select {|k| !history.include?(k)}

        queue += candidates
      end
      @board[coord[0]][coord[1]].revealed = true
    end

  end

  def game_over?
    a = nil
    b = true
    nonbombcounter = 0

    @board.each do |row|
      row.each do |spot|
        if spot.revealed
          if spot.bomb
            a = true
          else
            nonbombcounter += 1
          end
        end
      end
    end

    @bomblist.each do |location|
      if @board[location[0]][location[1]].flagged == false
        b = false
      end
    end

    #game is over if:
      #bomb has been revealed
      #all bombs flagged AND all non-bombs have been revealed

    a || (b && nonbombcounter == ((@board.size)**2 - @bomblist.count))
  end

  def run_game
    @start_time = Time.now
    until game_over?
      player_move = get_input
      if player_move == "s"
        @end_time = Time.now
        @total_time += @end_time - @start_time
        puts "#{@total_time} seconds"
        save_game
        next
      end
      apply_move(player_move)
      print_board
    end
    @end_time = Time.now
    @total_time += @end_time - @start_time

    puts "Game ended. Time taken is #{@total_time} seconds"
    @bomblist.each do |bomb|
      if @board[bomb[0]][bomb[1]].revealed
        puts "YOU HIT A BOMB \n\n"
        @board.each do |row|
          row.each do |spot|
            spot.revealed = true
          end
        end
        print_board
        return
      end
    end
    puts "You won!"
    print_board
    high_scores(@total_time)
  end

  def high_scores(total_time)
    puts "What is your name?"
    name = gets.chomp
    high_scores = {name => total_time}

    a = File.readlines("high_scores.txt")
    a.each do |line|
      individual_scores = JSON.parse(line)
      high_scores = high_scores.merge(individual_scores)
    end

    sorted_times = high_scores.sort_by {|k, v| v }
    puts "\nHigh score list is:"
    sorted_times.each do |k, v|
      puts "#{k}: #{v} seconds"
    end

    File.open("high_scores.txt", "w") do |f|
      f.puts "#{high_scores.to_json}"
      f.close
    end
  end

  def begin_game
    puts "New Game. 9x9 or a 16x16 game? [9/16]?"
    make_board(gets.chomp.to_i)
    puts "Game start!"
    print_board
    run_game
  end

  def save_game
    puts "What do you want to name your save?"
    filename = gets.chomp
    a = self.to_yaml
    savefile = File.open("#{filename}.txt", "w")
    savefile.puts a
    savefile.close
  end

end

class Minesweeper

  def initialize

    puts "Welcome to Minesweeper. [N]ew or [L]oad game?"
    input = gets.chomp.downcase
    case input
      when "n"
        a = Game.new
        a.begin_game
      when "l"
        puts "Enter load file name"
        filename = gets.chomp
        loadfile = File.new("#{filename}.txt")
        loaded_game = YAML::load(loadfile)

        loaded_game.print_board
        loaded_game.run_game
      else
        puts "Invalid answer"
    end
  end
end
