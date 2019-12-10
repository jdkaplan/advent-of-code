# frozen_string_literal: true

program = File.read(File.join(__dir__, 'input'))

def run(mem)
  pc = 0
  loop do
    case mem[pc]
    when 1
      r1, r2, r3 = mem[pc+1], mem[pc+2], mem[pc+3]
      mem[r3] = mem[r1] + mem[r2]
      pc += 4
    when 2
      r1, r2, r3 = mem[pc+1], mem[pc+2], mem[pc+3]
      mem[r3] = mem[r1] * mem[r2]
      pc += 4
    when 99
      return
    else
      raise StandardError, "unexpected opcode: #{opcode}"
    end
  end
end

mem = program.split(',').map(&:to_i)
mem[1] = 12
mem[2] = 2
run(mem)
puts mem[0]
