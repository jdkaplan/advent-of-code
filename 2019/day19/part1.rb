# frozen_string_literal: true

require_relative 'intcode'

Cell = Struct.new(:x, :y)

class Drone
  def initialize(program, target)
    @computer = Intcode::Computer.new(program.as_memory) { on_input }
    @input_queue = [target.x, target.y]
  end

  def on_input
    @input_queue.shift
  end

  def run
    @computer.next_output
  end
end

program = Intcode.read(File.join(__dir__, 'input'))

affected = 0
(0...50).each do |y|
  (0...50).each do |x|
    drone = Drone.new(program, Cell.new(x, y))
    case drone.run
    when 0
      print '.'
    when 1
      print '#'
      affected += 1
    end
  end
  print "\n"
end
puts affected
