# frozen_string_literal: true

answer = 0
File.open(File.join(__dir__, 'input')) do |file|
  file.readlines.each do |line|
    mass = line.to_i
    answer += (mass / 3).truncate - 2
  end
end
puts answer
