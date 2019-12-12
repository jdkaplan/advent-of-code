# frozen_string_literal: true

require 'set'
require_relative 'intcode'

Point = Struct.new(:x, :y) do
  def to_s
    "(#{x}, #{y})"
  end
end

class Hull
  def initialize
    @panels = Hash.new { |hash, key| hash[key] = :black }
    @painted = Set.new
  end

  def color_at(point)
    @panels[point]
  end

  def paint(point, color)
    @painted << point
    @panels[point] = color
  end

  def painted
    @painted.count
  end

  def corners
    min_x = +Float::INFINITY
    min_y = +Float::INFINITY
    max_x = -Float::INFINITY
    max_y = -Float::INFINITY

    @panels.keys.each do |p|
      min_x = [min_x, p.x].min
      min_y = [min_y, p.y].min
      max_x = [max_x, p.x].max
      max_y = [max_y, p.y].max
    end

    upper_left = Point.new(min_x, min_y)
    lower_right = Point.new(max_x, max_y)
    [upper_left, lower_right]
  end

  def to_s
    tl, br = corners

    s = String.new
    (tl.y..br.y).each do |y|
      (tl.x..br.x).each do |x|
        s << char(color_at(Point.new(x, y)))
      end
      s << "\n"
    end
    s
  end

  def char(code)
    case code
    when :black
      ' '
    when :white
      # Unicode full block
      "\u2588"
    else
      raise ArgumentError, "unexpected color code: #{code}"
    end
  end
end

class DoneExecuting < StandardError; end

class Robot
  def initialize(program, hull)
    @computer = Intcode::Computer.new(program.as_memory) { on_input }
    @hull = hull
    @facing = :up
    @position = Point.new(0, 0)
  end

  def step
    color_output = nil
    direction_output = nil

    color_output = tick until color_output
    direction_output = tick until direction_output

    @hull.paint(@position, color(color_output))
    @facing = turn(@facing, direction_output)
    @position = move(@position, @facing)
  end

  def tick
    ret = @computer.tick
    raise DoneExecuting if ret == :done_executing

    ret
  end

  def on_input
    color = @hull.color_at(@position)
    case color
    when :black
      0
    when :white
      1
    else
      raise ArgumentError, "unexpected color: #{color}"
    end
  end

  def color(code)
    case code
    when 0
      :black
    when 1
      :white
    else
      raise ArgumentError, "unexpected color code: #{code}"
    end
  end

  DIRECTIONS = %i[up right down left].freeze

  def turn(facing, direction_code)
    idx = DIRECTIONS.index(facing)
    case direction_code
    when 0
      # left 90 degrees (ccw)
      next_idx = (idx - 1) % DIRECTIONS.length
    when 1
      # right 90 degrees (cw)
      next_idx = (idx + 1) % DIRECTIONS.length
    else
      raise ArgumentError, "unexpected direction code: #{direction_code}"
    end
    DIRECTIONS.fetch(next_idx)
  end

  def move(pos, direction)
    case direction
    when :up
      Point.new(pos.x, pos.y - 1)
    when :down
      Point.new(pos.x, pos.y + 1)
    when :left
      Point.new(pos.x - 1, pos.y)
    when :right
      Point.new(pos.x + 1, pos.y)
    else
      raise ArgumentError, "unexpected direction: #{direction}"
    end
  end
end

hull = Hull.new
hull.paint(Point.new(0, 0), :white)

program = Intcode.read(File.join(__dir__, 'input'))
robot = Robot.new(program, hull)

loop do
  robot.step
rescue DoneExecuting
  break
end

puts hull
