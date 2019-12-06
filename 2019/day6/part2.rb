# frozen_string_literal: true

require 'set'

class Body
  attr_reader :name, :satellites
  attr_accessor :parent

  def initialize(name)
    @name = name
    @satellites = []
  end

  def <<(satellite)
    @satellites << satellite
    satellite.parent = self
  end

  def inspect
    "<Body #{name}, #{satellites.map(&:name).inspect}>"
  end

  def to_s
    name
  end

  def direct_orbits
    @direct_orbits ||= @satellites.length + @satellites.sum(&:direct_orbits)
  end

  def indirect_orbits(depth = 0)
    @indirect_orbits ||= @satellites.sum do |sat|
      depth + sat.indirect_orbits(depth + 1)
    end
  end

  @@registry = {}

  def self.get_or_create(name)
    if @@registry.key? name
      @@registry[name]
    else
      body = new(name)
      @@registry[name] = body
    end
  end

  def self.get(name)
    @@registry[name]
  end
end

def parse(input)
  input.lines.map do |line|
    center_name, satellite_name = line.strip.split(')')
    center = Body.get_or_create center_name
    satellite = Body.get_or_create satellite_name
    center << satellite
  end
end

input = File.read(File.join(__dir__, 'input'))

parse(input)

def find_path(start, goal)
  queue = [[start.parent]]
  visited = Set.new
  visited << start
  until queue.empty?
    path = queue.shift
    state = path[-1]
    next if visited.include? state

    visited << state
    return path if state.satellites.include? goal

    children = state.satellites
    children << state.parent if state.parent
    children.each do |child|
      queue << path + [child]
    end
  end
  nil
end

you = Body.get 'YOU'
santa = Body.get 'SAN'
path = find_path(you, santa)
puts path.length - 1
