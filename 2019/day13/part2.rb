# frozen_string_literal: true

require 'io/console'
require_relative 'intcode'

Cell = Struct.new(:x, :y)

class Screen
  attr_reader :tiles

  def initialize
    @tiles = {}
  end

  def draw(x, y, tile)
    @tiles[Cell.new(x, y)] = tile
  end

  def to_s
    tl, br = corners

    s = String.new
    (tl.y..br.y).each do |y|
      (tl.x..br.x).each do |x|
        s << char(Cell.new(x, y))
      end
      s << "\n"
    end
    s
  end

  def ball
    @tiles.each_pair do |cell, value|
      return cell if value == :ball
    end
    nil
  end

  def paddle
    @tiles.each_pair do |cell, value|
      return cell if value == :horizontal_paddle
    end
    nil
  end

  private

  def corners
    min_x = +Float::INFINITY
    min_y = +Float::INFINITY
    max_x = -Float::INFINITY
    max_y = -Float::INFINITY

    @tiles.keys.each do |p|
      min_x = [min_x, p.x].min
      min_y = [min_y, p.y].min
      max_x = [max_x, p.x].max
      max_y = [max_y, p.y].max
    end

    upper_left = Cell.new(min_x, min_y)
    lower_right = Cell.new(max_x, max_y)
    [upper_left, lower_right]
  end

  def char(cell)
    tile = @tiles[cell]
    case tile
    when :empty
      ' '
    when :wall
      '#'
    when :block
      'x'
    when :horizontal_paddle
      '-'
    when :ball
      'o'
    when nil
      ' '
    else
      raise StandardError, "Unexpected tile #{tile}"
    end
  end
end

class DoneExecuting < StandardError; end

class Game
  def initialize(program, screen, joystick)
    @computer = Intcode::Computer.new(program.as_memory) { on_input }
    @screen = screen
    @joystick = joystick
    @score = nil
  end

  def on_input
    @joystick.read
  end

  def run
    loop do
      step
      system 'clear'
      puts "Score: #{@score}"
      puts @screen
    rescue DoneExecuting
      return nil
    end
  end

  def step
    x = next_output
    y = next_output
    tile_id = next_output

    if x == -1 && y.zero?
      @score = tile_id
      return
    end

    case tile_id
    when 0
      @screen.draw(x, y, :empty)
    when 1
      @screen.draw(x, y, :wall)
    when 2
      @screen.draw(x, y, :block)
    when 3
      @screen.draw(x, y, :horizontal_paddle)
    when 4
      @screen.draw(x, y, :ball)
    else
      raise StandardError, "Unexpected tile ID: #{tile_id}"
    end
  end

  def next_output
    out = nil
    out = tick until out
    out
  end

  def tick
    ret = @computer.tick
    raise DoneExecuting if ret == :done_executing

    ret
  end
end

class ConsoleJoystick
  def read
    inp = nil
    inp = get_input until inp
    inp
  end

  def get_input
    ch = STDIN.getch
    exit 1 if ch == "\u0003"

    ch += STDIN.getch if ch == "\e"
    ch += STDIN.getch if ch == "\e["
    case ch
    when "\e[D"
      # left
      -1
    when "\e[C"
      # right
      +1
    when ' '
      # space
      0
    else
      puts "Invalid input: #{ch}"
    end
  end
end

class RobotJoystick
  def initialize(screen)
    @screen = screen
  end

  def read
    @screen.ball.x <=> @screen.paddle.x
  end
end

program = Intcode.read(File.join(__dir__, 'input-cheating'))
screen = Screen.new
joystick = RobotJoystick.new(screen)
# joystick = ConsoleJoystick.new
game = Game.new(program, screen, joystick)
game.run
