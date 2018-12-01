with open('input/day6') as f:
    puzzle_input = tuple(map(int, f.read().split()))

def cycle(banks):
    banks = list(banks)
    idx, blocks = max(enumerate(banks), key=lambda x: x[1])
    banks[idx] = 0
    idx = (idx+1) % len(banks)
    while blocks:
        banks[idx] += 1
        blocks -= 1
        idx = (idx+1) % len(banks)
    return tuple(banks)

def reallocate(banks):
    seen = set()
    seen.add(banks)
    count = 0
    while True:
        banks = cycle(banks)
        count += 1
        if banks in seen:
            return count
        seen.add(banks)

print(reallocate(puzzle_input))

def reallocate_loop(banks):
    seen = {}
    time = 0
    seen[banks] = time
    while True:
        banks = cycle(banks)
        time += 1
        if banks in seen:
            return time - seen[banks]
        seen[banks] = time

print(reallocate_loop(puzzle_input))
