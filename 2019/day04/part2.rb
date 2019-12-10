# frozen_string_literal: true

input = '' # TODO
range = Range.new(*input.split('-').map(&:to_i))

def pairwise(arr)
  arr[0...-1].zip(arr[1..])
end

def runs(digits)
  runs = []
  ref = digits.first
  run = ref.to_s
  digits[1..].each do |d|
    if d == ref
      run += d.to_s
    else
      runs << run
      ref = d
      run = ref.to_s
    end
  end
  runs << run
end

count = range.count do |n|
  # 1. All numbers in this range are six digits
  # 2. All numbers in this range are in this range

  digits = n.digits.reverse

  # 3. Two adjacent digits are the same
  double = runs(digits).any? { |run| run.length == 2 }

  # 4. Going from left to right, the digits *never decrease*
  monotonic = pairwise(digits).none? { |pair| pair.last < pair.first }

  double && monotonic
end
pp count
