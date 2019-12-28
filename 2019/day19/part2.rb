# frozen_string_literal: true

require_relative 'intcode'

class Drone
  def initialize(x, y)
    @computer = Intcode::Computer.new(@@program.as_memory) { on_input }
    @input_queue = [x, y]
  end

  def on_input
    @input_queue.shift
  end

  def run
    @computer.next_output
  end

  def self.program=(program)
    @@program = program
  end
end

def affected?(x, y)
  drone = Drone.new(x, y)
  drone.run == 1
end

def cells_in_row(y)
  x = (1.7 * y).floor
  x += 1 until affected?(x, y)
  lo = x
  x += 1 while affected?(x, y)
  hi = x
  hi - lo
end

def cells_in_column(x)
  y = (x / 2.1).floor
  y += 1 until affected?(x, y)
  lo = y
  y += 1 while affected?(x, y)
  hi = y
  hi - lo
end

Drone.program = Intcode.read(File.join(__dir__, 'input'))

Y = 254
X = 1066
