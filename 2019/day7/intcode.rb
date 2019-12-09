# frozen_string_literal: true

require 'forwardable'

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

  class Program
    def initialize(mem)
      @initial_state = mem
    end

    def as_memory
      Memory.new(@initial_state.clone)
    end

    def run(&user_input)
      Computer.new(as_memory).run(&user_input)
    end
  end

  class Memory
    extend Forwardable

    def_delegator :@cells, :[]
    def_delegator :@cells, :[]=

    def initialize(cells)
      @cells = cells
    end

    def to_s
      batch_size = 10
      s = String.new
      @cells.each_slice(batch_size).each_with_index do |batch, idx|
        prefix = idx * batch_size
        s << "#{prefix}: #{batch.join(' ')}\n"
      end
      s
    end

    def [](idx)
      raise ArgumentError, "index out of range: #{idx}" if idx.negative? || idx >= @cells.length

      @cells[idx]
    end

    def []=(idx, val)
      raise ArgumentError, "index out of range: #{idx}" if idx.negative? || idx >= @cells.length

      @cells[idx] = val
    end
  end

  class Computer
    def initialize(mem, &block)
      @mem = mem
      @ip = 0
      @input_block = block
    end

    def on_output(&block)
      @output_block = block
    end

    def run
      loop do
        return if tick == :done_executing
      end
    end

    def tick
      case operation(@mem[@ip])
      when 1
        add!
      when 2
        mul!
      when 3
        input!(&@input_block)
      when 4
        output!(&@output_block)
      when 5
        branch_if_not_zero!
      when 6
        branch_if_zero!
      when 7
        less_than!
      when 8
        equal!
      when 99
        :done_executing
      else
        raise StandardError, "unexpected opcode: #{opcode}"
      end
    end

    private

    def add!
      mode = modes(@mem[@ip])
      a = read(@ip + 1, mode[0])
      b = read(@ip + 2, mode[1])
      r = @mem[@ip + 3]
      raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

      @mem[r] = a + b
      @ip += 4
    end

    def mul!
      mode = modes(@mem[@ip])
      a = read(@ip + 1, mode[0])
      b = read(@ip + 2, mode[1])
      r = @mem[@ip + 3]
      raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

      @mem[r] = a * b
      @ip += 4
    end

    def input!(&user_input)
      mode = modes(@mem[@ip])
      r = @mem[@ip + 1]
      raise StandardError, "unexpected mode: #{mode[0]}" if mode[0] != 0

      @mem[r] = input(&user_input)
      @ip += 2
    end

    def output!(&user_output)
      mode = modes(@mem[@ip])
      output = read(@ip + 1, mode[0])
      user_output.call output if block_given?
      @ip += 2
    end

    def branch_if_not_zero!
      mode = modes(@mem[@ip])
      a = read(@ip + 1, mode[0])
      b = read(@ip + 2, mode[1])
      @ip = a.zero? ? @ip + 3 : b
    end

    def branch_if_zero!
      mode = modes(@mem[@ip])
      a = read(@ip + 1, mode[0])
      b = read(@ip + 2, mode[1])
      @ip = a.zero? ? b : @ip + 3
    end

    def less_than!
      mode = modes(@mem[@ip])
      a = read(@ip + 1, mode[0])
      b = read(@ip + 2, mode[1])
      r = @mem[@ip + 3]
      raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

      @mem[r] = a < b ? 1 : 0
      @ip += 4
    end

    def equal!
      mode = modes(@mem[@ip])
      a = read(@ip + 1, mode[0])
      b = read(@ip + 2, mode[1])
      r = @mem[@ip + 3]
      raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

      @mem[r] = a == b ? 1 : 0
      @ip += 4
    end

    def input
      if block_given?
        inp = yield
        raise "Invalid input: #{inp}" unless inp.is_a?(Numeric)

        return inp
      end

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
        @mem[val]
      when 1
        val
      else
        raise StandardError, "unexpected mode: #{mode}"
      end
    end

    def read(addr, mode)
      param(@mem[addr], mode)
    end
  end
end
