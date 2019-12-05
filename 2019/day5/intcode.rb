# frozen_string_literal: true

module Intcode
  def self.read(filename)
    Program.new File.read(filename).split(',').map(&:to_i)
  end

  class Program
    attr_reader :mem
    def initialize(mem)
      @mem = mem
    end

    def run(noun, verb)
      mem = @mem.clone
      mem[1] = noun
      mem[2] = verb
      pc = 0
      loop do
        case mem[pc]
        when 1
          r1 = mem[pc + 1]
          r2 = mem[pc + 2]
          r3 = mem[pc + 3]
          mem[r3] = mem[r1] + mem[r2]
          pc += 4
        when 2
          r1 = mem[pc + 1]
          r2 = mem[pc + 2]
          r3 = mem[pc + 3]
          mem[r3] = mem[r1] * mem[r2]
          pc += 4
        when 99
          return mem[0]
        else
          raise StandardError, "unexpected opcode: #{opcode}"
        end
      end
    end
  end
end
