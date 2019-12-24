# frozen_string_literal: true

require 'set'

require 'pqueue'

require_relative 'search'

Cell = Struct.new(:r, :c) do
  def to_s
    "(#{r}, #{c})"
  end

  def neighbors
    [
      Cell.new(r + 1, c),
      Cell.new(r - 1, c),
      Cell.new(r, c + 1),
      Cell.new(r, c - 1)
    ]
  end
end

class Maze
  def initialize(text)
    @text = text
  end

  def to_s
    @text
  end

  def grid
    @grid ||= @text.strip.lines.map(&:strip)
  end

  def width
    @width ||= grid.first.size
  end

  def height
    @height ||= grid.size
  end

  def cells
    @cells ||=
      (0...height).flat_map do |r|
        (0...width).map do |c|
          Cell.new(r, c)
        end
      end
  end

  def entrance
    @entrance ||= cells.find { |cell| grid[cell.r][cell.c] == '@' }
  end

  def keys
    @keys ||= cells.reduce(Set.new) { |keys, cell| keys + keys_at(cell) }
  end

  def in_bounds?(cell)
    cell.r >= 0 && cell.r < height && cell.c >= 0 && cell.c < width
  end

  def keys_at(cell)
    return Set.new unless in_bounds?(cell)

    text = grid[cell.r][cell.c]
    if key?(text)
      Set.new([text])
    else
      Set.new
    end
  end

  def position_for(key)
    key_to_cell[key]
  end

  def key_to_cell
    @key_to_cell ||= cells.reduce({}) do |hash, cell|
      keys_at(cell).each do |key|
        hash = hash.merge(key => cell)
      end
      hash
    end
  end

  KEY_REGEX = /^[a-z]$/.freeze
  DOOR_REGEX = /^[A-Z]$/.freeze

  def key?(text)
    KEY_REGEX.match(text)
  end

  def can_enter?(cell, keys)
    return false unless in_bounds?(cell)

    text = grid[cell.r][cell.c]
    case text
    when '.', '@', KEY_REGEX
      true
    when '#'
      false
    when DOOR_REGEX
      keys.include? text.downcase
    end
  end

  def door?(text)
    DOOR_REGEX.match(text)
  end
end

State = Struct.new(:cell, :keys) do
  def to_s
    "#{cell} #{keys}"
  end
end

def old_soln(maze)
  start = State.new(maze.entrance, Set.new)
  is_goal = ->(state) { state.keys == maze.keys }
  get_neighbors = lambda do |state|
    state.cell
         .neighbors
         .select { |cell| maze.can_enter?(cell, state.keys) }
         .map { |cell| [State.new(cell, state.keys + maze.keys_at(cell)), 1] }
  end
  state = Search.uniform_cost(start, get_neighbors, is_goal)
  state.path.size - 1
end

def all_keys_cost(maze)
  # Top-level search: key ordering

  start = []
  is_goal = ->(keys) { Set.new(keys) == maze.keys }
  get_neighbors = lambda do |keys|
    # Inner level search: point-to-point cost

    source = keys.empty? ? maze.entrance : maze.position_for(keys[-1])

    vertices = maze.cells.select { |cell| maze.can_enter?(cell, keys) }

    edges = Hash.new { |hash, key| hash[key] = {} }
    vertices.each do |cell|
      cell.neighbors
          .select { |neighbor| maze.can_enter?(neighbor, keys) }
          .each do |neighbor|
        edges[cell][neighbor] = 1
      end
    end

    dist = Search.dijkstra(vertices, edges, source)

    neighbors = {}
    (maze.keys - keys).each do |key|
      cost = dist[maze.position_for(key)]
      neighbors[keys + [key]] = cost unless cost == +Float::INFINITY
    end
    neighbors
  end
  result = Search.uniform_cost(start, get_neighbors, is_goal)
  puts "Order: #{result.state}"
  result.cost
end

def solve(input)
  maze = Maze.new(input)

  puts maze
  puts "#{maze.height} x #{maze.width}"
  puts "Keys: #{maze.keys.sort}"

  cost = old_soln(maze)
  puts "Old: #{cost}"
  cost = all_keys_cost(maze)
  puts "New: #{cost}"
end

input = File.read(File.join(__dir__, 'input'))
tiny = <<~TINY # 8 steps
  #########
  #b.A.@.a#
  #########
TINY
small = <<~SMALL # 86 steps
  ########################
  #f.D.E.e.C.b.A.@.a.B.c.#
  ######################.#
  #d.....................#
  ########################
SMALL
ex1 = <<~EX1 # 132 steps
  ########################
  #...............b.C.D.f#
  #.######################
  #.....@.a.B.c.d.A.e.F.g#
  ########################
EX1
ex2 = <<~EX2 # 136 steps
  #################
  #i.G..c...e..H.p#
  ########.########
  #j.A..b...f..D.o#
  ########@########
  #k.E..a...g..B.n#
  ########.########
  #l.F..d...h..C.m#
  #################
EX2
ex3 = <<~EX3 # 136 steps
  ########################
  #@..............ac.GI.b#
  ###d#e#f################
  ###A#B#C################
  ###g#h#i################
  ########################
EX3

solve ex2
puts 'done'
