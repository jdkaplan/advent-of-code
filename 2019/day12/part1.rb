# frozen_string_literal: true

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

input = File.read(File.join(__dir__, 'input'))
positions = parse(input)
moons = positions.map { |pos| Moon.new(pos, Velocity.new(0, 0, 0)) }

1000.times do
  moons = move(gravity(moons))
end

puts moons.sum(&:energy)
