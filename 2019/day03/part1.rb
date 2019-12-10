# frozen_string_literal: true

require 'pp'

input = File.read(File.join(__dir__, 'input'))

def wires(input)
  input.lines.map do |line|
    wire_points(line.strip.split(','))
  end
end

class Point
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def inspect
    "Point(#{x}, #{y})"
  end

  def hash
    [x, y].hash
  end

  def eql?(other)
    x == other.x && y == other.y
  end

  def right(dy)
    Point.new(x, y + dy)
  end

  def left(dy)
    Point.new(x, y - dy)
  end

  def down(dx)
    Point.new(x - dx, y)
  end

  def up(dx)
    Point.new(x + dx, y)
  end

  def move(direction, delta)
    case direction
    when 'U'
      up(delta)
    when 'D'
      down(delta)
    when 'L'
      left(delta)
    when 'R'
      right(delta)
    else
      raise StandardError, "Unexpected move direction: #{direction}"
    end
  end

  def manhattan_distance_to(other)
    (x - other.x).abs + (y - other.y).abs
  end
end

def wire_points(moves)
  pos = Point.new(0, 0)
  # NOTE: We don't include the origin in the list of points because that's not
  # considered a valid intersection.
  points = []
  moves.each do |move|
    direction = move[0]
    delta = move[1..].to_i
    delta.times do
      pos = pos.move(direction, 1)
      points << pos
    end
  end
  points
end

wire1, wire2 = wires(input)
origin = Point.new(0, 0)
intersections = (wire1 & wire2).sort do |p1, p2|
  d1 = p1.manhattan_distance_to origin
  d2 = p2.manhattan_distance_to origin
  d1 - d2
end

pp intersections.first.manhattan_distance_to origin
