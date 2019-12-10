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
    @input_queue = [phase]
    @computer = Intcode::Computer.new(memory) { @input_queue.shift }
  end

  def amplify(input)
    @input_queue << input
    output = nil
    output = @computer.tick until output
    output
  end

  def input(val)
    @input_queue << val
  end
end

def thrust(program, phases)
  a = Amplifier.new(program.as_memory, phases[0])
  b = Amplifier.new(program.as_memory, phases[1])
  c = Amplifier.new(program.as_memory, phases[2])
  d = Amplifier.new(program.as_memory, phases[3])
  e = Amplifier.new(program.as_memory, phases[4])

  cache = -Float::INFINITY
  out1 = a.amplify(0)
  loop do
    out2 = b.amplify(out1)
    out3 = c.amplify(out2)
    out4 = d.amplify(out3)
    out5 = e.amplify(out4)
    return cache if out5 == :done_executing

    cache = out5
    out1 = a.amplify(out5)
  end
end

program = Intcode.read(File.join(__dir__, 'input'))

phase_space = [5, 6, 7, 8, 9].permutation(5)

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
