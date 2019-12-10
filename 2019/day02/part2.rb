# frozen_string_literal: true

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
      return mem[0]
    else
      raise StandardError, "unexpected opcode: #{opcode}"
    end
  end
end

def solve(program)
  (0...99).each do |noun|
    (0...99).each do |verb|
      puts "Trying noun = #{noun}, verb = #{verb} ..."
      mem = program.clone
      mem[1] = noun
      mem[2] = verb
      output = run(mem)
      puts "Output: #{output}"
      if output == 19690720
        return [noun, verb, 100*noun + verb]
      end
    end
  end
end

input = File.read(File.join(__dir__, 'input'))
program = input.split(',').map(&:to_i)
puts solve(program)
