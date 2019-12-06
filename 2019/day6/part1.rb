# frozen_string_literal: true

require 'set'

class Body
  attr_reader :name, :satellites
  def initialize(name)
    @name = name
    @satellites = []
  end

  def <<(satellite)
    @satellites << satellite
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
  Body.get 'COM'
end

input = File.read(File.join(__dir__, 'input'))

com = parse(input)
puts com.direct_orbits + com.indirect_orbits
