# frozen_string_literal: true

require_relative 'intcode'

Cell = Struct.new(:r, :c) do
  def neighbors
    [
      Cell.new(r + 1, c),
      Cell.new(r - 1, c),
      Cell.new(r, c + 1),
      Cell.new(r, c - 1)
    ]
  end
end

class World
  def initialize
    @cells = {}
    @max_r = -1
    @max_c = -1
  end

  def set(cell, contents)
    @cells[cell] = contents
    @max_r = [@max_r, cell.r].max
    @max_c = [@max_c, cell.c].max
  end

  def intersections
    @cells.keys.select { |cell| intersection? cell }
  end

  def intersection?(cell)
    scaffold?(cell) && cell.neighbors.all? { |neighbor| scaffold?(neighbor) }
  end

  SCAFFOLDS = %i[scaffold robot_up robot_down robot_left robot_right] .freeze

  def scaffold?(cell)
    SCAFFOLDS.include? @cells[cell]
  end

  def to_s
    s = String.new
    (0..@max_r).each do |r|
      (0..@max_c).each do |c|
        s << char(@cells[Cell.new(r, c)])
      end
      s << "\n"
    end
    s
  end

  CHAR_TO_CONTENTS = {
    '#' => :scaffold,
    '.' => :open,
    '^' => :robot_up,
    'v' => :robot_down,
    '<' => :robot_left,
    '>' => :robot_right,
    'x' => :robot_tumbling
  }.freeze

  CONTENTS_TO_CHAR = {
    scaffold: '#',
    open: '.',
    robot_up: '^',
    robot_down: 'v',
    robot_left: '<',
    robot_right: '>',
    robot_tumbling: 'x'
  }.freeze

  def self.parse(text)
    r = c = 0
    world = new
    text.each_char do |char|
      if char == "\n"
        r += 1
        c = 0
        next
      end
      contents = CHAR_TO_CONTENTS.fetch(char)
      world.set(Cell.new(r, c), contents)
      c += 1
    end
    world
  end

  private

  def char(contents)
    CONTENTS_TO_CHAR.fetch(contents)
  end
end

class Calibrator
  def initialize(program)
    @computer = Intcode::Computer.new(program.as_memory)
    @world = nil
  end

  def calibrate
    text = ''
    while (i = tick)
      text += i.chr
    end
    @world = World.parse(text)
    alignment(@world.intersections)
  end

  def alignment(intersections)
    intersections.sum do |cell|
      cell.r * cell.c
    end
  end

  def tick
    @computer.next_output
  end
end

program = Intcode.read(File.join(__dir__, 'input'))
c = Calibrator.new(program)
puts c.calibrate
