# frozen_string_literal: true

def fuel_needed(mass)
  [(mass / 3).truncate - 2, 0].max
end

def total_fuel(mass)
  fuel = 0
  current = mass
  while current.positive?
    current = fuel_needed(current)
    fuel += current
  end
  fuel
end

fuel = 0
File.open(File.join(__dir__, 'input')) do |file|
  file.readlines.each do |line|
    mass = line.to_i
    fuel += total_fuel(mass)
  end
end
puts fuel
