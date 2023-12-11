import std/algorithm
import std/deques
import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables

proc dbg[T](v: T): T = (echo(v); v)

type Point = tuple
  r: int
  c: int

type Universe = object
  rows: int
  cols: int
  grid: Table[Point, char]
  galaxies: seq[Point]

func parseUniverse(text: string): Universe =
  let lines = text.strip.splitLines()
  result.rows = lines.len
  result.cols = lines[0].len

  for (r, line) in enumerate(lines):
    for (c, sym) in enumerate(line):
      result.grid[(r, c)] = sym

      if sym == '#':
        result.galaxies.add (r, c)

func expandRows(rows: seq[string]): seq[string] =
  for (r, row) in enumerate(rows):
    result.add(row)
    if '#' notin row:
      result.add(row)

func transpose(rows: seq[string]): seq[string] =
  for c in 0 ..< rows[0].len:
    var col = ""
    for r in 0 ..< rows.len:
      col = col & rows[r][c]
    result.add col

func expand(text: string): string =
  let rows = text.strip.splitlines
  let e1 = rows.expandRows

  let cols = e1.transpose
  let e2 = cols.expandRows

  e2.transpose.join("\n")

func manhattan(a: Point, b: Point): int =
  abs(a.r - b.r) + abs(a.c - b.c)

proc part1(): int =
  let text = readFile("input/day11.txt")
  let u = parseUniverse(expand(text))

  for (i, a) in enumerate(u.galaxies):
    for b in u.galaxies[i..^1]:
      result.inc manhattan(a, b)

func hasGalaxyRow(u: Universe, r: int): bool =
  for g in u.galaxies:
    if g.r == r:
      return true
  return false

func hasGalaxyCol(u: Universe, c: int): bool =
  for g in u.galaxies:
    if g.c == c:
      return true
  return false

func expand(u: Universe, amt: int): seq[Point] =
  result = u.galaxies
  for r in countdown(u.rows - 1, 0):
    if u.hasGalaxyRow(r):
      continue

    var gs: seq[Point]
    for g in result:
      if g.r > r:
        gs.add (g.r + amt, g.c)
      else:
        gs.add g
    result = gs

  for c in countdown(u.cols - 1, 0):
    if u.hasGalaxyCol(c):
      continue

    var gs: seq[Point]
    for g in result:
      if g.c > c:
        gs.add (g.r, g.c + amt)
      else:
        gs.add g
    result = gs

proc part2(): int =
  let text = readFile("input/day11.txt")
  let universe = parseUniverse(text)
  let galaxies = universe.expand(1_000_000 - 1)

  for (i, a) in enumerate(galaxies):
    for b in galaxies[i..^1]:
      result.inc manhattan(a, b)

echo part1()
echo part2()
