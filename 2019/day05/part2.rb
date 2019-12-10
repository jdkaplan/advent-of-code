# frozen_string_literal: true

require_relative 'intcode'

input = File.join(__dir__, 'input')
program = Intcode.read(input)
puts 236453
program.run { 5 }
