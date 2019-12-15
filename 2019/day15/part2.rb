# frozen_string_literal: true

require 'set'
require_relative 'intcode'

Cell = Struct.new(:x, :y) do
  def north
    Cell.new(x, y - 1)
  end

  def south
    Cell.new(x, y + 1)
  end

  def west
    Cell.new(x - 1, y)
  end

  def east
    Cell.new(x + 1, y)
  end

  def neighbors
    [north, south, west, east]
  end

  def direction_to(other)
    dx = other.x - x
    dy = other.y - y

    if dy.negative?
      :north
    elsif dy.positive?
      :south
    elsif dx.negative?
      :west
    elsif dx.positive?
      :east
    end
  end
end

class Map
  def initialize
    @grid = {}
  end

  def set_content!(cell, content)
    @grid[cell] = content
  end

  def get(cell)
    @grid[cell]
  end

  def printable(droid_position)
    tl, br = corners(droid_position)

    s = String.new
    (tl.y..br.y).each do |y|
      (tl.x..br.x).each do |x|
        cell = Cell.new(x, y)
        s << if cell == droid_position
               'D'
             else
               char(cell)
             end
      end
      s << "\n"
    end
    s
  end

  def goal
    @grid.each_pair do |cell, content|
      return cell if content == :oxygen
    end
    nil
  end

  def oxygenate
    iterations = 0
    until @grid.each_pair.all? { |_cell, contents| %i[oxygen wall].include? contents }
      grid = @grid.clone
      oxygenated = grid.keys.select { |cell| grid[cell] == :oxygen }
      iterations += 1

      if (iterations % 10).zero?
        print_state!
        sleep 0.01
      end

      oxygenated.each do |cell|
        cell.neighbors.each do |neighbor|
          next if [:wall, nil].include? grid[neighbor]

          grid[neighbor] = :oxygen
        end
      end
      @grid = grid
    end

    print_state!
    iterations
  end

  def print_state!
    system 'clear'
    puts printable(nil)
  end

  private

  def corners(droid_position)
    min_x = droid_position&.x || +Float::INFINITY
    max_x = droid_position&.x || -Float::INFINITY
    min_y = droid_position&.y || +Float::INFINITY
    max_y = droid_position&.y || -Float::INFINITY

    @grid.keys.each do |p|
      min_x = [min_x, p.x].min
      min_y = [min_y, p.y].min
      max_x = [max_x, p.x].max
      max_y = [max_y, p.y].max
    end

    upper_left = Cell.new(min_x, min_y)
    lower_right = Cell.new(max_x, max_y)
    [upper_left, lower_right]
  end

  def char(cell)
    content = get(cell)
    case content
    when :wall
      '#'
    when :open
      '.'
    when :oxygen
      'O'
    when nil
      ' '
    else
      raise StandardError, "unknown content: #{content}"
    end
  end
end

class Droid
  def initialize(program, map)
    @computer = Intcode::Computer.new(program.as_memory) { on_input }
    @map = map

    @direction = nil
    @position = Cell.new(0, 0)
    @mode = :exploration

    @map.set_content!(@position, :open)
  end

  MOVEMENT_COMMANDS = { north: 1, south: 2, west: 3, east: 4 }.freeze

  def on_input
    MOVEMENT_COMMANDS.fetch(@direction)
  end

  def run
    iterations = 0
    loop do
      result = step!
      if (iterations % 100).zero?
        print_state!
        sleep 0.01
      end

      return result if result

      iterations += 1
    end
  end

  private

  def step!
    case @mode
    when :exploration
      step_exploration!
      nil
    when :pathfinding
      step_pathfinding
    end
  end

  def step_pathfinding
    search(Cell.new(0, 0), @map.goal)
  end

  def step_exploration!
    if @path.nil? || @path.length.zero? || @position == @path[-1] || blocked?(@path)
      target = closest_unexplored_cell
      if target.nil?
        # Nothing left to see!
        @mode = :pathfinding
        return
      end
      @path = replan(target)
    end

    @direction = next_movement
    status = next_output!
    case status
    when 0
      set_content!(@direction, :wall)
      # no movement
    when 1
      set_content!(@direction, :open)
      move!(@direction)
    when 2
      set_content!(@direction, :oxygen)
      move!(@direction)
    else
      raise StandardError, "unknown status: #{status}"
    end
  end

  def next_movement
    @path.shift if @position == @path[0]
    target = @path[0]
    @position.direction_to(target)
  end

  def blocked?(path)
    path.any? do |cell|
      @map.get(cell) == :wall
    end
  end

  def closest_unexplored_cell
    path = bfs(
      @position,
      ->(cell) { cell.neighbors.reject { |c| @map.get(c) == :wall } },
      ->(cell) { @map.get(cell).nil? },
    )
    path.nil? ? nil : path[-1]
  end

  def replan(goal)
    search(@position, goal)
  end

  def search(start, goal)
    bfs(
      start,
      ->(cell) { cell.neighbors.reject { |c| @map.get(c) == :wall } },
      ->(cell) { cell == goal },
    )
  end

  def move!(direction)
    @position = @position.send(direction)
    @path.shift if @position == @path[0]
  end

  def next_output!
    out = nil
    out = @computer.tick until out
    out
  end

  def set_content!(direction, content)
    neighbor = @position.send(direction)
    @map.set_content!(neighbor, content)
  end

  def print_state!
    system 'clear'
    puts @map.printable(@position)
  end
end

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

program = Intcode.read(File.join(__dir__, 'input'))
map = Map.new
droid = Droid.new(program, map)
droid.run
puts map.oxygenate
