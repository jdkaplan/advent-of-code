with open('input/day5') as f:
    puzzle_input = tuple(int(line) for line in f.read().splitlines())

def step(jumps, index):
    jump = jumps[index]
    return (jumps[:index] + (offset(jump),) + jumps[index+1:]), index + jump

def escape(jumps):
    index = 0
    steps = 0
    while 0 <= index < len(jumps):
        jumps, index = step(jumps, index)
        steps += 1
    return steps

def offset(jump):
    return jump+1

#  print(escape(puzzle_input))

def offset(jump):
    return jump + (-1)**(jump >= 3)

print(escape(puzzle_input))
