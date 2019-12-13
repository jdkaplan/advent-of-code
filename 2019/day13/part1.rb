# frozen_string_literal: true

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
      '_'
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
  def initialize(program, screen)
    @computer = Intcode::Computer.new(program.as_memory) { on_input }
    @screen = screen
  end

  def on_input
    raise NotImplementedError
  end

  def run
    loop do
      step
      system 'clear'
      puts @screen
      sleep 0.01
      blocks = @screen.tiles.values.count { |val| val == :block }
      puts blocks
    rescue DoneExecuting
      return nil
    end
  end

  def step
    x = next_output
    y = next_output
    tile_id = next_output

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

program = Intcode.read(File.join(__dir__, 'input'))
screen = Screen.new
game = Game.new(program, screen)
game.run
