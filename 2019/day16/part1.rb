# frozen_string_literal: true

def fft(input)
  base = [0, 1, 0, -1]
  input.each_with_index.map do |_n, i|
    pattern = base.flat_map { |e| [e] * (i + 1) }
    pattern *= (input.length.fdiv pattern.length).ceil + 1
    pattern.shift
    cross(input, pattern[0...input.length])
  end
end

def cross(input, pattern)
  total = input.zip(pattern).sum { |a, b| a * b }
  total.abs % 10
end

input = File.read(File.join(__dir__, 'input'))
numbers = input.strip.split('').map(&:to_i)

100.times do |_i|
  numbers = fft(numbers)
end
puts numbers[0, 8].join
