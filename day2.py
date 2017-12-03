def parse(text):
    return [[int(num) for num in line.split('\t')] for line in text.splitlines()]

with open('input/day2') as inp:
    puzzle_input = parse(inp.read())

def part1(sheet):
    return sum(max(row) - min(row) for row in sheet)

assert part1([
    [5, 1, 9, 5],
    [7, 5, 3],
    [2, 4, 6, 8],
]) == 18

print(part1(puzzle_input))

from itertools import combinations

def part2(sheet):
    s = 0
    for row in sheet:
        for n, m in combinations(row, 2):
            lo = min(n, m)
            hi = max(n, m)
            if hi % lo == 0:
                s += hi // lo
                break
    return s

assert part2([
    [5, 9, 2, 8],
    [9, 4, 7, 3],
    [3, 8, 6, 5],
]) == 9

print(part2(puzzle_input))
