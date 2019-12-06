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
      @input = nil
      @initial_state = mem
    end

    def run(&user_input)
      mem = Memory.new(@initial_state.clone)
      Executor.new(mem).run(&user_input)
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
      output = String.new
      @cells.each_slice(batch_size).each_with_index do |batch, idx|
        prefix = idx * batch_size
        output << "#{prefix}: #{batch.join(' ')}\n"
      end
      output
    end
  end

  class DoneExecuting < StandardError; end

  class Executor
    def initialize(mem)
      @mem = mem
      @ip = 0
    end

    def run(&user_input)
      loop do
        tick(&user_input)
      rescue DoneExecuting
        # TODO: Stop using exceptions for control flow
        return
      end
    end

    def tick(&user_input)
      opcode = operation(@mem[@ip])
      mode = modes(@mem[@ip])
      case opcode
      when 1
        a = read(@ip + 1, mode[0])
        b = read(@ip + 2, mode[1])
        r = @mem[@ip + 3]
        raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

        @mem[r] = a + b
        @ip += 4
      when 2
        a = read(@ip + 1, mode[0])
        b = read(@ip + 2, mode[1])
        r = @mem[@ip + 3]
        raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

        @mem[r] = a * b
        @ip += 4
      when 3
        r = @mem[@ip + 1]
        raise StandardError, "unexpected mode: #{mode[0]}" if mode[0] != 0

        @mem[r] = input(&user_input)
        @ip += 2
      when 4
        output = read(@ip + 1, mode[0])
        puts "output: #{output}"
        @ip += 2
      when 5
        a = read(@ip + 1, mode[0])
        b = read(@ip + 2, mode[1])
        @ip = a.zero? ? @ip + 3 : b
      when 6
        a = read(@ip + 1, mode[0])
        b = read(@ip + 2, mode[1])
        @ip = a.zero? ? b : @ip + 3
      when 7
        a = read(@ip + 1, mode[0])
        b = read(@ip + 2, mode[1])
        r = @mem[@ip + 3]
        raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

        @mem[r] = a < b ? 1 : 0
        @ip += 4
      when 8
        a = read(@ip + 1, mode[0])
        b = read(@ip + 2, mode[1])
        r = @mem[@ip + 3]
        raise StandardError, "unexpected mode: #{mode[2]}" if mode[2] != 0

        @mem[r] = a == b ? 1 : 0
        @ip += 4
      when 99
        raise DoneExecuting
      else
        raise StandardError, "unexpected opcode: #{opcode}"
      end
    end

    private

    def input
      print 'input> '
      if block_given?
        inp = yield
        puts inp
        return inp
      end

      gets.to_i
    end

    def default_input; end

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

    # Operators

    def add; end
  end
end
