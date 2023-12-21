# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'
require 'sorbet-struct-comparable'

module Day20
  class Pulse < T::Enum
    enums do
      High = new
      Low = new
    end
  end

  class Wire < T::Struct
    include T::Struct::ActsAsComparable

    const :src, String
    const :dst, String
    const :pulse, Pulse
  end

  class Module
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.returns(String) }
    def name; end

    sig { abstract.returns(T::Array[String]) }
    def dests; end

    sig { abstract.params(source: String, pulse: Pulse).returns(T::Array[Wire]) }
    def handle(source, pulse); end
  end

  class Broadcaster < Module
    extend T::Sig

    sig { override.returns(String) }
    attr_reader :name

    sig { override.returns(T::Array[String]) }
    attr_reader :dests

    sig { params(name: String, dests: T::Array[String]).void }
    def initialize(name, dests)
      @name = name
      @dests = dests
    end

    sig { override.params(source: String, pulse: Pulse).returns(T::Array[Wire]) }
    def handle(source, pulse)
      @dests.map do |dst|
        Wire::new(src: @name, dst: dst, pulse: pulse)
      end
    end
  end

  class FlipFlop < Module
    extend T::Sig

    sig { override.returns(String) }
    attr_reader :name

    sig { override.returns(T::Array[String]) }
    attr_reader :dests

    sig { params(name: String, dests: T::Array[String]).void }
    def initialize(name, dests)
      @name = name
      @dests = dests
      @inputs = T.let([], T::Array[String])
      @on = false
    end

    sig { override.params(source: String, pulse: Pulse).returns(T::Array[Wire]) }
    def handle(source, pulse)
      return [] if pulse == Pulse::High

      if @on
        @on = false
        output = Pulse::Low
      else
        @on = true
        output = Pulse::High
      end

      @dests.map do |dst|
        Wire::new(src: @name, dst: dst, pulse: output)
      end
    end
  end

  class Conjunction < Module
    extend T::Sig

    sig { override.returns(String) }
    attr_reader :name

    sig { override.returns(T::Array[String]) }
    attr_reader :dests

    sig { override.params(name: String, dests: T::Array[String]).void }
    def initialize(name, dests)
      @name = name
      @dests = dests
      @inputs = T.let({}, T::Hash[String, Pulse])
    end

    sig { params(name: String).void }
    def register_input(name)
      @inputs[name] = Pulse::Low
    end

    sig { override.params(source: String, pulse: Pulse).returns(T::Array[Wire]) }
    def handle(source, pulse)
      @inputs[source] = pulse

      output = if @inputs.all? { |k, v| v == Pulse::High }
        Pulse::Low
      else
        Pulse::High
      end

      @dests.map do |dst|
        Wire::new(src: @name, dst: dst, pulse: output)
      end
    end
  end

  class Machine
    extend T::Sig

    def initialize(text)
      @modules = T.let({}, T::Hash[String, Module])

      text.strip.split("\n").each do |line|
        name, dests = line.split('->').map(&:strip)
        dests = dests.split(',').map(&:strip)

        mod = if name[0] == '%'
          FlipFlop::new(name[1..name.length], dests)
        elsif name[0] == '&'
          Conjunction::new(name[1..name.length], dests)
        elsif name == 'broadcaster'
          Broadcaster::new(name, dests)
        else
          raise StandardError, name
        end

        @modules[mod.name] = mod
      end

      @modules.each_pair do |src_name, src_mod|
        src_mod.dests.each do |dst_name|
          dst = @modules[dst_name]
          if dst.is_a? Conjunction
            dst.register_input(src_name)
          end
        end
      end
    end

    sig { returns(T::Hash[Pulse, Integer] )}
    def push_button
      counts = {
        Pulse::Low => 0,
        Pulse::High => 0,
      }

      queue = T.let([], T::Array[Wire])
      queue << Wire::new(src: 'button', dst: 'broadcaster', pulse: Pulse::Low)

      while !queue.empty?
        wire = T.must(queue.shift)
        counts[wire.pulse] += 1

        mod = @modules[wire.dst] or next
        mod.handle(wire.src, wire.pulse).each do |output|
          queue << output
        end
      end

      counts
    end
  end

  class << self
    extend T::Sig

    sig { params(path: String).returns(Integer) }
    def part1(path)
      text = File.read(path)
      machine = Machine::new(text)
      low = high = 0
      1_000.times do
        pulses = machine.push_button
        high += pulses.fetch(Pulse::High)
        low += pulses.fetch(Pulse::Low)
      end
      high * low
    end
  end
end

puts Day20::part1 File.join(__dir__, 'input/test.txt')
puts Day20::part1 File.join(__dir__, 'input/day20.txt')
