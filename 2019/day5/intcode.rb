# frozen_string_literal: true

module Intcode
  def self.read(filename)
    parse File.read(filename)
  end

  def self.parse(input)
    parsed = input
             .gsub(/^#.*$/, '')
             .gsub('\s', '')
             .split(',')
             .map(&:to_i)
    Program.new parsed
  end

  class Memory
    def initialize(cells)
      @cells = cells
    end

    def to_s
      batch_size = 10
      output = String.new
      @cells.each_slice(batch_size).each_with_index do |batch, idx|
        prefix = idx * batch_size
        output << "#{prefix}: #{batch.join(' ')}\n"
      end
      output
    end

    def [](addr)
      @cells[addr]
    end

    def []=(addr, val)
      @cells[addr] = val
    end
  end

  class Program
    attr_accessor :mem
    def initialize(mem)
      @input = nil
      @initial_state = mem
    end

    def run(&user_input)
      @mem = Memory.new(@initial_state.clone)
      ip = 0
      loop do
        opcode = operation(mem[ip])
        mode = modes(mem[ip])
        case opcode
        when 1
          r1 = mem[ip + 1]
          r2 = mem[ip + 2]
          r3 = mem[ip + 3]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

          mem[r3] = a + b
          ip += 4
        when 2
          r1 = mem[ip + 1]
          r2 = mem[ip + 2]
          r3 = mem[ip + 3]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

          mem[r3] = a * b
          ip += 4
        when 3
          r1 = mem[ip + 1]
          raise StandardError, "unexpected mode: #{mode[0]}" if mode[0] != 0

          mem[r1] = user_input.nil? ? input : user_input.call
          ip += 2
        when 4
          r1 = mem[ip + 1]
          output = param(r1, mode[0])
          puts "output: #{output}"

          ip += 2
        when 5
          r1 = mem[ip + 1]
          r2 = mem[ip + 2]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          if !a.zero?
            ip = b
          else
            ip += 3
          end
        when 6
          r1 = mem[ip + 1]
          r2 = mem[ip + 2]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          if a.zero?
            ip = b
          else
            ip += 3
          end
        when 7
          r1 = mem[ip + 1]
          r2 = mem[ip + 2]
          r3 = mem[ip + 3]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

          mem[r3] = a < b ? 1 : 0
          ip += 4
        when 8
          r1 = mem[ip + 1]
          r2 = mem[ip + 2]
          r3 = mem[ip + 3]
          a = param(r1, mode[0])
          b = param(r2, mode[1])
          raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

          mem[r3] = a == b ? 1 : 0
          ip += 4
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
      return default_input if @input.nil?

      inp = @input.call
      puts inp
      inp
    end

    def default_input
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
