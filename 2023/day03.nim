import std/sets
import std/enumerate
import std/tables
import std/sequtils
import std/strutils

const digits = "0123456789"

func as_int(c: char): int = c.int - '0'.int

type Point = tuple
  r: int
  c: int

func neighbors(p: Point): seq[Point] =
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

type Slice = tuple
  lo: Point
  hi: Point

func row_range(s: Slice): seq[int] =
  toSeq(s.lo.r .. s.hi.r)

func col_range(s: Slice): seq[int] =
  toSeq(s.lo.c .. s.hi.c)

func contains(s: Slice, p: Point): bool =
  p.r in s.row_range and p.c in s.col_range

type Part = tuple
  id: int
  slice: Slice

func contains(part: Part, p: Point): bool =
  part.slice.contains(p)

type Grid = object
  rows: int
  cols: int
  table: Table[Point, char]
  parts: seq[Part]
  gears: seq[Point]

func parseGrid(text: string): Grid =
  result.table = initTable[Point, char]()

  let lines = text.strip.splitLines()
  result.rows = lines.len
  result.cols = lines[0].len

  for (r, line) in enumerate(lines):
    var part: Part
    var in_num = false

    for (c, sym) in enumerate(line):
      result.table[(r, c)] = sym

      if sym == '*':
        result.gears.add((r, c))

      if sym in digits:
        if in_num:
          part.slice.hi = (r, c)
          part.id = 10 * part.id + sym.as_int
        else:
          part.slice.lo = (r, c)
          part.slice.hi = (r, c)
          part.id = sym.as_int
        in_num = true
        continue

      if in_num:
        result.parts.add(part)
        in_num = false

    if in_num:
      result.parts.add(part)

func symbol(grid: Grid, p: Point): char =
  if p.r in 0 ..< grid.rows and p.c in 0 ..< grid.cols:
    grid.table[p]
  else:
    '.'

func text(grid: Grid, s: Slice): string =
  assert(s.lo.r == s.hi.r)
  let r = s.lo.r

  for c in s.col_range:
    result.add(grid.symbol((r, c)))

func is_attached(part: Part, grid: Grid): bool =
  let r = part.slice.lo.r
  for c in part.slice.col_range:
    for n in neighbors((r, c)):
      if part.contains(n):
        continue

      let nsym = grid.symbol(n)
      if nsym != '.':
        return true
  return false

proc part1(): int =
  let text = readFile("input/day03.txt")
  let grid = parseGrid(text)

  for part in grid.parts:
    assert(part.slice.lo.r == part.slice.hi.r)

    if part.is_attached(grid):
      result += grid.text(part.slice).parseInt

func get_containing(grid: Grid, p: Point): Part =
  for part in grid.parts:
    if part.contains(p):
      return part

func gear_neighbors(grid: Grid, p: Point): HashSet[Part] =
  for n in p.neighbors:
    if grid.symbol(n) in digits:
      result.incl(grid.get_containing(n))

proc part2(): int =
  let text = readFile("input/day03.txt")
  let grid = parseGrid(text)

  for gear in grid.gears:
    let parts = grid.gear_neighbors(gear)
    if parts.len != 2:
      continue

    var ratio = 1
    for part in parts:
      ratio *= grid.text(part.slice).parseInt

    result += ratio

echo part1()
echo part2()
