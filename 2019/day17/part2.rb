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

  def neighbor(dir)
    case dir
    when :up
      Cell.new(r - 1, c)
    when :down
      Cell.new(r + 1, c)
    when :left
      Cell.new(r, c - 1)
    when :right
      Cell.new(r, c + 1)
    end
  end

  def can_move?(dir, scaffold)
    scaffold.include? neighbor(dir)
  end

  def move(dir)
    neighbor dir
  end
end

State = Struct.new(:pos, :dir)

def bfs(start, get_neighbors, is_goal)
  queue = [[start]]
  visited = Set.new
  until queue.empty?
    path = queue.shift
    state = path[-1]
    next if visited.include? state

    visited << state
    return path if is_goal.call(state)

    children = get_neighbors.call(state).reject { |cell| visited.include? cell }
    children.each do |child|
      queue << path + [child]
    end
  end
  nil
end

def turn(old, new)
  dirs = %i[up right down left]
  i = dirs.index old
  j = dirs.index new

  lefts = ((i - j) % 4).abs
  rights = ((j - i) % 4).abs
  if lefts < rights
    ['L'] * lefts
  else
    ['R'] * rights
  end
end

def valid_turns(dir)
  case dir
  when :up, :down
    %i[left right]
  when :left, :right
    %i[up down]
  end
end

def follow_path(start_cell, start_dir, scaffold)
  path = []
  cell = start_cell
  dir = start_dir
  loop do
    while cell.can_move?(dir, scaffold)
      cell = cell.move dir
      path << 1
    end
    old_dir = dir
    dir = valid_turns(old_dir).find do |d|
      cell.can_move?(d, scaffold)
    end
    break if dir.nil?

    path.concat turn(old_dir, dir)
  end
  path
end

def condense(path)
  condense_forward(path).each_slice(2)
end

def condense_forward(path)
  new_path = [0]
  path.each do |move|
    both_numeric = move.is_a?(Numeric) && new_path.last.is_a?(Numeric)
    new_path << (both_numeric ? new_path.pop + move : move)
  end
  new_path.shift if new_path.first.zero?
  new_path
end

def create_functions(actions)
  valid = proc { |p| p.join(',').size < 20 }
  (1..5).reverse.each do |a_length|
    actions.uniq.repeated_permutation(a_length).select(&valid).each do |_a|
      (1..5).reverse.each do |b_length|
        actions.uniq.repeated_permutation(b_length).select(&valid).each do |_b|
          (1..5).reverse.each do |c_length|
            actions.uniq.repeated_permutation(c_length).select(&valid).each do |_c|
              Plan.new
            end
          end
        end
      end
    end
  end
end

Plan = Struct.new(:main, :a, :b, :c) do
  def expand
    main
      .gsub(/A/, a)
      .gsub(/B/, b)
      .gsub(/C/, c)
  end

  def validate!
    errors = []

    errors << 'Main is too long' unless main.size < 20
    errors << 'A is too long' unless a.size < 20
    errors << 'B is too long' unless b.size < 20
    errors << 'C is too long' unless c.size < 20
    errors << 'Main has invalid characters' unless main.chars.all? { |c| ['A', 'B', 'C', ','].include? c }

    errors.each { |error| puts error }
    raise StandardError, 'Plan failed to validate!' unless errors.empty?
  end
end

MEMORY_LIMIT = 20 # characters

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

  ROBOTS = %i[up down left right].freeze

  def plan
    # From my input, I know that my robot starts on one end of the scaffolding.
    # Also from my input, I know that following the path directly (continuing
    # "forward" at every intersection) gets the robot to the end.  I'm going to
    # hope that I can write a program that takes every loop the "right" way
    # first.
    start = @cells.find do |_cell, contents|
      ROBOTS.include? contents
    end
    start_cell, start_dir = start

    scaffold = @cells.keys.select { |cell| scaffold?(cell) }
    path = follow_path(start_cell, start_dir, scaffold)
    condense(path)
  end

  def intersections
    @cells.keys.select { |cell| intersection? cell }
  end

  def intersection?(cell)
    scaffold?(cell) && cell.neighbors.all? { |neighbor| scaffold?(neighbor) }
  end

  SCAFFOLDS = %i[scaffold up down left right].freeze

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
    '^' => :up,
    'v' => :down,
    '<' => :left,
    '>' => :right,
    'x' => :tumbling
  }.freeze

  CONTENTS_TO_CHAR = {
    scaffold: '#',
    open: '.',
    up: '^',
    down: 'v',
    left: '<',
    right: '>',
    tumbling: 'x'
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
  attr_reader :world

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

class Robot
  def initialize(program, input_queue)
    @computer = Intcode::Computer.new(program.as_memory) { on_input }
    @input_queue = input_queue.clone
  end

  def on_input
    @input_queue.shift
  end

  def tick
    @computer.next_output
  end
end

main = 'A,B,A,C,B,C,A,C,B,C'
a = 'L,8,R,10,L,10'
b = 'R,10,L,8,L,8,L,10'
c = 'L,4,L,6,L,8,L,8'
plan = Plan.new(main, a, b, c)

plan.validate!

def to_input(function)
  function.chars.map(&:ord) + ["\n".ord]
end

video_feed = 'n'
input_queue = [plan.main, plan.a, plan.b, plan.c].flat_map { |fn| to_input(fn) }
input_queue.concat "#{video_feed}\n".chars.map(&:ord)

program = Intcode.read(File.join(__dir__, 'input2'))
robot = Robot.new(program, input_queue)

outputs = []
while (out = robot.tick)
  outputs << out
end

outputs[0...-1].each do |out|
  print out.chr
end
puts outputs.last
