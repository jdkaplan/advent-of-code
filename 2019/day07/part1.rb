# frozen_string_literal: true

require_relative 'intcode'

def inputter(queue)
  idx = 0
  proc do
    input = queue[idx]
    idx += 1
    input
  end
end

class Amplifier
  def initialize(memory, phase)
    @memory = memory
    @phase = phase
  end

  def amplify(input)
    next_input = inputter([@phase, input])
    computer = Intcode::Computer.new(@memory) do
      inp = next_input.call
      # print 'input> '
      # puts inp
      inp
    end
    output = nil
    computer.on_output do |out|
      output = out
    end
    computer.run
    output
  end
end

def thrust(program, phases)
  a = Amplifier.new(program.as_memory, phases[0]).amplify(0)
  b = Amplifier.new(program.as_memory, phases[1]).amplify(a)
  c = Amplifier.new(program.as_memory, phases[2]).amplify(b)
  d = Amplifier.new(program.as_memory, phases[3]).amplify(c)
  e = Amplifier.new(program.as_memory, phases[4]).amplify(d)
  e
end

program = Intcode.read(File.join(__dir__, 'input'))

phase_space = [0, 1, 2, 3, 4].permutation(5)

max_thrust = -Float::INFINITY
max_phases = nil
phase_space.each do |phases|
  t = thrust(program, phases)
  next unless t > max_thrust

  max_thrust = t
  max_phases = phases
end

pp max_phases
puts max_thrust
