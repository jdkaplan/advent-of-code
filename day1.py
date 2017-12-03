def part1(digits):
    return sum(int(d) for i, d in enumerate(digits) if d == digits[(i+1) % len(digits)])

for inp, out in [
        ('1122', 3),
        ('1111', 4),
        ('1234', 0),
        ('91212129', 9),
]:
    assert part1(inp) == out, f'Expected {out}, got {part1(inp)}'

def part2(digits):
    return sum(int(d) for i, d in enumerate(digits) if d == digits[(i+len(digits)//2) % len(digits)])

for inp, out in [
        ('1212', 6),
        ('1221', 0),
        ('123425', 4),
        ('123123', 12),
        ('12131415', 4),
]:
    assert part2(inp) == out, f'Expected {out}, got {part2(inp)}'

puzzle_input = 'TODO'

print(part1(puzzle_input))
print(part2(puzzle_input))
