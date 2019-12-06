# frozen_string_literal: true

module Intcode
  def self.read(filename)
    input = File.read(filename)
                .gsub(/^#.*$/, '')
                .gsub('\s', '')
    Program.new(parse(input))
  end

  def self.parse(input)
    input.split(',').map(&:to_i)
  end

  class Program
    attr_accessor :mem
    def initialize(mem)
      @mem = mem.clone

      def @mem.to_s
        batch_size = 10
        output = String.new
        each_slice(batch_size).each_with_index do |batch, idx|
          prefix = idx * batch_size
          output << "#{prefix}: #{batch.join(' ')}\n"
        end
        output
      end
    end

    def run
      pc = 0
      loop do
        opcode = operation(mem[pc])
        mode = modes(mem[pc])
        case opcode
        when 1
          r1 = mem[pc + 1]
          r2 = mem[pc + 2]
          r3 = mem[pc + 3]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

          mem[r3] = a + b
          pc += 4
        when 2
          r1 = mem[pc + 1]
          r2 = mem[pc + 2]
          r3 = mem[pc + 3]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

          mem[r3] = a * b
          pc += 4
        when 3
          r1 = mem[pc + 1]
          raise StandardError, "unexpected mode: #{mode[0]}" if mode[0] != 0

          mem[r1] = input
          pc += 2
        when 4
          r1 = mem[pc + 1]
          output = param(r1, mode[0])
          puts "output: #{output}"

          pc += 2
        when 99
          return mem[0]
        else
          raise StandardError, "unexpected opcode: #{opcode}"
        end
      end
    end

    private

    def input
      print 'input> '
      gets.to_i
    end

    def operation(cell)
      (cell % 100)
    end

    def modes(cell)
      m = Hash.new(0)
      (cell / 100).truncate.digits.each_with_index do |d, i|
        m[i] = d
      end
      m
    end

    def param(val, mode)
      case mode
      when 0
        mem[val]
      when 1
        val
      else
        raise StandardError, "unexpected mode: #{mode}"
      end
    end
  end
end
