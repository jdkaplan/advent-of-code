# frozen_string_literal: true

require 'set'

Position = Struct.new(:x, :y, :z) do
  def to_s
    "(#{x}, #{y}, #{z})"
  end

  def plus(v)
    Position.new(x + v.x, y + v.y, z + v.z)
  end
end

Velocity = Struct.new(:x, :y, :z) do
  def to_s
    "(#{x}, #{y}, #{z})"
  end

  def plus(dx, dy, dz)
    Velocity.new(x + dx, y + dy, z + dz)
  end
end

Moon = Struct.new(:pos, :vel) do
  def to_s
    "pos=#{pos} vel=#{vel}"
  end

  def energy
    potential_energy * kinetic_energy
  end

  def potential_energy
    pos.x.abs + pos.y.abs + pos.z.abs
  end

  def kinetic_energy
    vel.x.abs + vel.y.abs + vel.z.abs
  end
end

class AxisCache
  def initialize(axis)
    @axis = axis
    @store = []
  end

  def <<(moons)
    @store << by_axis(moons)
  end

  def include?(moons)
    @store.include? by_axis(moons)
  end

  def index(moons)
    @store.index by_axis(moons)
  end

  private

  def by_axis(moons)
    case @axis
    when :x
      moons.map { |moon| [moon.pos.x, moon.vel.x] }
    when :y
      moons.map { |moon| [moon.pos.y, moon.vel.y] }
    when :z
      moons.map { |moon| [moon.pos.z, moon.vel.z] }
    end
  end
end

def parse(input)
  positions = []
  input.lines.each do |line|
    coords = {}
    line.strip[1...-1].split(',').each do |chunk|
      key, val = chunk.split('=')
      coords[key.strip] = val.to_i
    end
    positions << Position.new(coords['x'], coords['y'], coords['z'])
  end
  positions
end

def pairs_with_indices(arr)
  (0...(arr.length)).each do |i|
    ((i + 1)...(arr.length)).each do |j|
      yield(arr[i], i, arr[j], j)
    end
  end
end

def gravity(moons)
  dvs = 4.times.map { Velocity.new(0, 0, 0) }
  pairs_with_indices(moons) do |a, i, b, j|
    # From a's perspective
    dx = b.pos.x <=> a.pos.x
    dy = b.pos.y <=> a.pos.y
    dz = b.pos.z <=> a.pos.z
    dvs[i] = dvs[i].plus(dx, dy, dz)
    dvs[j] = dvs[j].plus(-dx, -dy, -dz)
  end
  moons.each_with_index.map do |moon, i|
    dv = dvs[i]
    Moon.new(moon.pos, moon.vel.plus(dv.x, dv.y, dv.z))
  end
end

def move(moons)
  moons.map do |moon|
    Moon.new(moon.pos.plus(moon.vel), moon.vel)
  end
end

def step(moons)
  move(gravity(moons))
end

def find_repeat(moons)
  # x_repeated + nx * x_period
  # y_repeated + ny * y_period
  # z_repeated + nz * z_period
end

input = File.read(File.join(__dir__, 'input'))
# input = <<~FIRST
#   <x=-1, y=0, z=2>
#   <x=2, y=-10, z=-7>
#   <x=4, y=-8, z=8>
#   <x=3, y=5, z=-1>
# FIRST
# input = <<~SECOND
#   <x=-8, y=-10, z=0>
#   <x=5, y=5, z=10>
#   <x=2, y=-7, z=3>
#   <x=9, y=-8, z=-3>
# SECOND
positions = parse(input)
moons = positions.map { |pos| Moon.new(pos, Velocity.new(0, 0, 0)) }

x = AxisCache.new(:x)
y = AxisCache.new(:y)
z = AxisCache.new(:z)

x << moons
y << moons
z << moons

x_first = nil
x_period = nil
y_first = nil
y_period = nil
z_first = nil
z_period = nil

i = 0
until x_period && y_period && z_period
  i += 1
  puts "#{i} steps" if (i % 100).zero?
  moons = move(gravity(moons))

  if x_period.nil? && x.include?(moons)
    x_first ||= x.index moons
    x_period ||= i - x_first
  end

  if y_period.nil? && y.include?(moons)
    y_first ||= y.index moons
    y_period ||= i - y_first
  end

  if z_period.nil? && z.include?(moons)
    z_first ||= z.index moons
    z_period ||= i - z_first
  end
end
puts i
pp [x_first, x_period]
pp [y_first, y_period]
pp [z_first, z_period]

def factors(n)
  res = Hash.new { |hash, key| hash[key] = 0 }
  d = 2
  until n == 1
    while (n % d).zero?
      res[d] += 1
      n /= d
    end
    d += 1
  end
  res
end

def lcm(*ints)
  facts = []
  ints.each do |i|
    facts << factors(i)
  end
  res = Hash.new { |hash, key| hash[key] = 0 }
  facts.each do |fs|
    fs.each_pair do |f, times|
      res[f] = [res[f], times].max
    end
  end

  product = 1
  res.each_pair do |f, rep|
    product *= f**rep
  end
  product
end

pp lcm(x_period, y_period, z_period)
