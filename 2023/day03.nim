import std/sets
import std/enumerate
import std/tables
import std/strutils

const digits = "0123456789"

type Coord = tuple
  r: int
  c: int

type Slice = tuple
  lo: Coord
  hi: Coord

type Grid = object
  rows: int
  cols: int
  table: Table[Coord, char]
  numbers: seq[Slice]
  gears: seq[Coord]

proc parseGrid(text: string): Grid =
  result.table = initTable[Coord, char]()

  let lines = text.strip.splitLines()
  result.rows = lines.len
  result.cols = lines[0].len

  for (r, line) in enumerate(lines):
    var num: Slice
    var in_num = false

    for (c, sym) in enumerate(line):
      result.table[(r, c)] = sym

      if sym == '*':
        result.gears.add((r, c))

      if sym in digits:
        if in_num:
          num.hi = (r, c)
        else:
          num.lo = (r, c)
          num.hi = (r, c)
        in_num = true
        continue

      if in_num:
        result.numbers.add(num)
        in_num = false

    if in_num:
      result.numbers.add(num)


func neighbors(p: Coord): seq[Coord] =
  for (dr, dc) in [
    (-1, -1),
    (-1, 0),
    (-1, +1),
    (0, -1),
    # (0, 0)
    (0, +1),
    (+1, -1),
    (+1, 0),
    (+1, +1),
  ]:
    result.add((p.r + dr, p.c + dc))

proc grid_sym(grid: Grid, p: Coord): char =
  if 0 <= p.r and p.r < grid.rows and 0 <= p.c and p.c < grid.cols:
    grid.table[p]
  else:
    '.'

proc grid_slice(grid: Grid, s: Slice): string =
  for r in s.lo.r .. s.hi.r:
    for c in s.lo.c .. s.hi.c:
      result.add(grid_sym(grid, (r, c)))

proc has_neighbor(grid: Grid, s: Slice): bool =
  let r = s.lo.r
  for c in s.lo.c .. s.hi.c:
    for n in neighbors((r, c)):
      if n.r == r and s.lo.c <= n.c and n.c <= s.hi.c:
        continue

      let nsym = grid_sym(grid, n)
      if nsym != '.':
        return true
  return false

proc part1(): int =
  let text = readFile("input/day03.txt")
  let grid = parseGrid(text)

  for num in grid.numbers:
    assert(num.lo.r == num.hi.r)

    if grid.has_neighbor(num):
      result += grid_slice(grid, num).parseInt

proc get_containing(grid: Grid, p: Coord): Slice =
  for num in grid.numbers:
    if p.r == num.lo.r and num.lo.c <= p.c and p.c <= num.hi.c:
      return num

proc gear_neighbors(grid: Grid, p: Coord): HashSet[Slice] =
  for n in p.neighbors:
    if grid.grid_sym(n)in digits:
      result.incl(grid.get_containing(n))

proc part2(): int =
  let text = readFile("input/day03.txt")
  let grid = parseGrid(text)

  for gear in grid.gears:
    let nums = grid.gear_neighbors(gear)
    if nums.len != 2:
      continue

    var ratio = 1
    for s in nums:
      ratio *= grid.grid_slice(s).parseInt

    result += ratio

echo part1()
echo part2()
