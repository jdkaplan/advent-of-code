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

    attr_accessor :relative_base

    def initialize(cells)
      @cells = cells
      @relative_base = 0
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

    def read(addr, mode)
      # raise ArgumentError, "address out of range: #{addr}" if addr.negative? || addr >= @cells.length
      return 0 if addr.negative? || addr >= @cells.length

      case mode
      when INDIRECT_MODE
        read(@cells[addr], IMMEDIATE_MODE)
      when IMMEDIATE_MODE
        @cells[addr]
      when RELATIVE_MODE
        read(@cells[addr] + relative_base, IMMEDIATE_MODE)
      else
        raise ArgumentError, "unexpected mode: #{mode}"
      end
    end

    def write(addr, mode, val)
      raise ArgumentError, "address out of range: #{addr}" if addr.negative? || addr >= @cells.length

      case mode
      when INDIRECT_MODE
        r = @cells[addr]
        @cells[r] = val
      when IMMEDIATE_MODE
        raise ArgumentError, 'writes are not allowed in immediate mode'
        @cells[addr]
      when RELATIVE_MODE
        r = @cells[addr] + relative_base
        @cells[r] = val
      else
        raise ArgumentError, "unexpected mode: #{mode}"
      end
    end
  end

  INDIRECT_MODE = 0
  IMMEDIATE_MODE = 1
  RELATIVE_MODE = 2

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

    def next_output
      loop do
        out = tick
        return nil if out == :done_executing
        return out if out
      end
    end

    def tick
      opcode = operation(@mem[@ip])
      case opcode
      when 1
        add!
        nil
      when 2
        mul!
        nil
      when 3
        input!(&@input_block)
        nil
      when 4
        output!(&@output_block)
      when 5
        branch_if_not_zero!
        nil
      when 6
        branch_if_zero!
        nil
      when 7
        less_than!
        nil
      when 8
        equal!
        nil
      when 9
        move_relative_base!
        nil
      when 99
        :done_executing
      else
        raise StandardError, "unexpected opcode: #{opcode}"
      end
    end

    private

    def add!
      mode = modes(@mem[@ip])
      a = @mem.read(@ip + 1, mode[0])
      b = @mem.read(@ip + 2, mode[1])
      @mem.write(@ip + 3, mode[2], a + b)
      @ip += 4
    end

    def mul!
      mode = modes(@mem[@ip])
      a = @mem.read(@ip + 1, mode[0])
      b = @mem.read(@ip + 2, mode[1])
      @mem.write(@ip + 3, mode[2], a * b)
      @ip += 4
    end

    def input!(&user_input)
      mode = modes(@mem[@ip])
      inp = input(&user_input)
      @mem.write(@ip + 1, mode[0], inp)
      @ip += 2
    end

    def output!(&user_output)
      mode = modes(@mem[@ip])
      output = @mem.read(@ip + 1, mode[0])
      user_output.call output if block_given?
      @ip += 2
      output
    end

    def branch_if_not_zero!
      mode = modes(@mem[@ip])
      a = @mem.read(@ip + 1, mode[0])
      b = @mem.read(@ip + 2, mode[1])
      @ip = a.zero? ? @ip + 3 : b
    end

    def branch_if_zero!
      mode = modes(@mem[@ip])
      a = @mem.read(@ip + 1, mode[0])
      b = @mem.read(@ip + 2, mode[1])
      @ip = a.zero? ? b : @ip + 3
    end

    def less_than!
      mode = modes(@mem[@ip])
      a = @mem.read(@ip + 1, mode[0])
      b = @mem.read(@ip + 2, mode[1])
      val = a < b ? 1 : 0
      @mem.write(@ip + 3, mode[2], val)
      @ip += 4
    end

    def equal!
      mode = modes(@mem[@ip])
      a = @mem.read(@ip + 1, mode[0])
      b = @mem.read(@ip + 2, mode[1])
      val = a == b ? 1 : 0
      @mem.write(@ip + 3, mode[2], val)
      @ip += 4
    end

    def move_relative_base!
      mode = modes(@mem[@ip])
      delta = @mem.read(@ip + 1, mode[0])
      @mem.relative_base += delta
      @ip += 2
    end

    def input
      if block_given?
        inp = yield
        raise "Invalid input: #{inp.inspect}" unless inp.is_a?(Numeric)

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
  end
end
