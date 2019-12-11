# frozen_string_literal: true

class AsteroidBelt
  def initialize(text)
    @grid = parse(text)
  end

  def asteroids
    return @asteroids unless @asteroids.nil?

    @asteroids = []
    @grid.each_with_index do |line, y|
      line.chars.each_with_index do |cell, x|
        @asteroids << Asteroid.new(x, y) if cell == '#'
      end
    end
    @asteroids
  end

  private

  def parse(text)
    text.lines
  end
end

class Asteroid
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def neighbors(asteroids)
    by_direction = Hash.new { |hash, key| hash[key] = [] }
    asteroids.each do |asteroid|
      next if asteroid == self

      theta = direction_to(asteroid).normalize
      by_direction[theta] << asteroid
    end
    by_direction
  end

  def direction_to(other)
    dx = other.x - x
    dy = other.y - y
    Vector.new(dx, dy)
  end

  def distance_to(other)
    dx = other.x - x
    dy = other.y - y
    Math.sqrt(dx**2 + dy**2)
  end

  def inspect
    "<Asteroid: #{x},#{y}>"
  end

  def to_s
    "(#{x},#{y})"
  end
end

class Vector
  attr_reader :x, :y

  def initialize(x, y, normal = false)
    @x = x
    @y = y
    @normal = normal
  end

  def normalize
    return self if @normal

    div = gcd(@x.abs, @y.abs)
    Vector.new(Rational(@x / div), Rational(@y / div), true)
  end

  def ==(other)
    s = normalize
    o = other.normalize

    s.x == o.x && s.y == o.y
  end

  def eql?(other)
    self == other
  end

  def hash
    n = normalize
    [n.x, n.y].hash
  end

  def inspect
    "<Vector: #{x},#{y}>"
  end

  def to_s
    "(#{x},#{y})"
  end

  def from_vertical
    #                 (0,1)
    #                   0  /
    #                   |t/
    #                   |/
    # (-1,0) 3pi/2 -----+----- +pi/2 (1,0)
    #                   |
    #                   |
    #                  +pi
    #                (0,-1)
    -Math.atan2(x, y)
  end
end

def gcd(n, m)
  # Invariant: n >= m
  n, m = m, n if n < m
  n, m = m, n % m until m.zero?
  n
end

input = File.read(File.join(__dir__, 'input'))

belt = AsteroidBelt.new input

best = belt.asteroids.max_by do |asteroid|
  asteroid.neighbors(belt.asteroids).count
end
pp best

neighbors = best.neighbors(belt.asteroids)
directions = neighbors.keys.sort_by(&:from_vertical)
neighbors.values.each do |asteroids|
  asteroids.sort_by! do |asteroid|
    best.distance_to(asteroid)
  end
end

destroyed = []
until neighbors.values.all?(&:empty?)
  directions.each do |dir|
    next if neighbors[dir].empty?

    destroyed << neighbors[dir].shift
  end
end

winner = destroyed[199]
pp winner
puts 100 * winner.x + winner.y
