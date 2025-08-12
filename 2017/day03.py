puzzle_input = 0 # TODO

def cardinals(distance):
    d = 0
    distance[1] = d
    yield 1

    d += 1
    distance[2] = d
    yield 2

    while True:
        v = (2*d)**2 - (d-1)
        distance[v] = d
        yield v

        v = (2*d)**2 + (d+1)
        distance[v] = d
        yield v

        v = (2*d + 1)**2 - d
        distance[v] = d
        yield v

        v = (2*d + 1)**2 + (d+1)
        distance[v] = d + 1
        yield v

        d += 1

def closest_cardinals(n, distance):
    cs = cardinals(distance)
    lo = next(cs)
    hi = next(cs)
    while not lo <= n <= hi:
        lo, hi = hi, next(cs)
    return lo, hi

def manhattan_to_center(n):
    distance = {}
    best = sorted(closest_cardinals(n, distance), key=lambda x: abs(n - x))[0]
    return distance[best] + abs(n - best)

for inp, expected in [
    (1, 0),
    (2, 1),
    (12, 3),
    (23, 2),
    (1024, 31),
]:
    actual = manhattan_to_center(inp)
    assert actual == expected, f'Expected {expected} got {actual}'

print(manhattan_to_center(puzzle_input))

def walking_order():
    start = (0, 0)
    R, D, L, U = [(+1, 0), (0, -1), (-1, 0), (0, +1)]

    yield R
    yield U

    count = 2
    while True:
        for deltas in [(L, D), (R, U)]:
            for delta in deltas:
                for _ in range(count):
                    yield delta
            count += 1

def neighbors(cell):
    x, y = cell
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if dx == dy == 0: continue
            yield (x+dx, y+dy)

def sum_neighbors_until(limit):
    grid = {}
    deltas = walking_order()

    cell = (0, 0)
    grid[cell] = 1

    while True:
        x, y = cell
        dx, dy = next(deltas)
        cell = (x+dx, y+dy)
        value = sum(grid.get(n, 0) for n in neighbors(cell))
        grid[cell] = value
        if value > limit:
            return value

print(sum_neighbors_until(puzzle_input))
