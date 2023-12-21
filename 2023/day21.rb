# frozen_string_literal: true
# typed: true

require 'set'

require 'sorbet-runtime'
require 'sorbet-struct-comparable'

extend T::Sig

class Cell < T::Struct
  extend T::Sig
  include T::Struct::ActsAsComparable

  const :r, Integer
  const :c, Integer

  class << self
    extend T::Sig

    sig { params(r: Integer, c: Integer).returns(Cell) }
    def at(r, c) = Cell::new(r: r, c: c)
  end

  sig { returns(Cell) }
  def north = Cell::at(r - 1, c)

  sig { returns(Cell) }
  def south = Cell::at(r + 1, c)

  sig { returns(Cell) }
  def west  = Cell::at(r, c - 1)

  sig { returns(Cell) }
  def east  = Cell::at(r, c + 1)

  sig { returns(T::Array[Cell]) }
  def neighbors = [north, south, west, east]
end

class Garden
  extend T::Sig

  sig { returns(Cell) }
  attr_reader :start

  def initialize(text)
    @grid = T.let({}, T::Hash[Cell, String])

    text.strip.each_line.each_with_index do |line, r|
      line.strip.each_char.each_with_index do |char, c|
        @grid[Cell::at(r, c)] = char
        @start = Cell::at(r, c) if char == ?S
      end
    end
  end

  sig { params(cell: Cell).returns(T.nilable(String)) }
  def char(cell) = @grid[cell]

  sig { params(cell: Cell).returns(T::Boolean) }
  def is_plot?(cell)
    sym = char(cell) or return false
    sym != '#'
  end
end

class Gardener
  extend T::Sig

  sig { params(garden: Garden).void }
  def initialize(garden)
    @garden = garden
  end

  sig { params(starts: T::Set[Cell]).returns(T::Set[Cell]) }
  def step_hypothetically(starts)
    dests = Set::new
    starts.each do |start|
      dests.merge start.neighbors.select { |c| @garden.is_plot?(c) }
    end
    dests
  end
end

sig { params(path: String).returns(Integer) }
def part1(path)
  text = File.read(path)
  garden = Garden::new(text)
  gardener = Gardener::new(garden)

  pos = Set[garden.start]
  64.times do
    pos = gardener.step_hypothetically(pos)
  end
  pos.size
end

puts part1 File.join(__dir__, 'input/test.txt')
puts part1 File.join(__dir__, 'input/day21.txt')
