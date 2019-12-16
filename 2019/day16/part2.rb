# frozen_string_literal: true

def run(text)
  numbers = text.strip.split('').map(&:to_i) * 10_000
  offset = numbers[0, 7].join.to_i
  arr = numbers[offset..-1]

  100.times do
    # All coefficients are
    # * 0: when before output index
    # * 1: when at or after output index
    # The pattern is long enough that there are no -1's or later 0's.
    updated = []
    total = arr.sum
    arr.each do |elt|
      updated << total.abs % 10
      total -= elt
    end
    arr = updated
  end
  arr[0, 8].join
end

input = File.read(File.join(__dir__, 'input'))
puts run(input)
