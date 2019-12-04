# frozen_string_literal: true

input = '' # TODO
range = Range.new(*input.split('-').map(&:to_i))

def pairwise(arr)
  arr[0...-1].zip(arr[1..])
end

count = range.count do |n|
  # 1. All numbers in this range are six digits
  # 2. All numbers in this range are in this range

  digits = n.digits.reverse

  # 3. Two adjacent digits are the same
  double = pairwise(digits).any? { |pair| pair.first == pair.last }

  # 4. Going from left to right, the digits *never decrease*
  monotonic = pairwise(digits).none? { |pair| pair.last < pair.first }

  double && monotonic
end
pp count
