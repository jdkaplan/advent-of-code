from collections import defaultdict

registers = None

comparison = {
        '==': lambda x, y : registers[x] == y,
        '!=': lambda x, y : registers[x] != y,
        '>=': lambda x, y : registers[x] >= y,
        '<=': lambda x, y : registers[x] <= y,
        '<':  lambda x, y : registers[x] <  y,
        '>':  lambda x, y : registers[x] >  y,
}

def inc(x, y):
    registers[x] += y

def dec(x, y):
    registers[x] -= y

operation = {
        'inc': inc,
        'dec': dec,
}

class Instruction:
    def __init__(self, line):
        self.reg, self.op, self.delta, _, self.flag, self.comp, self.val = line.split()

    def evaluate(self):
        if comparison[self.comp](self.flag, int(self.val)):
            operation[self.op](self.reg, int(self.delta))


with open('input/day8') as f:
    puzzle_input = [Instruction(line) for line in f.read().splitlines()]

def largest(instructions):
    global registers
    registers = defaultdict(int)
    for i in instructions:
        i.evaluate()
    return max(registers.values())

def highest(instructions):
    global registers
    registers = defaultdict(int)
    high = float('-inf')
    for i in instructions:
        i.evaluate()
        high = max(high, max(registers.values()))
    return high

print(largest(puzzle_input))
print(highest(puzzle_input))
