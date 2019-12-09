# frozen_string_literal: true

require_relative 'intcode'

program = Intcode.read(File.join(__dir__, 'input'))
computer = Intcode::Computer.new(program.as_memory) { 1 }
computer.on_output { |out| puts out }
computer.run
