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

type Sketch = object
  rows: int
  cols: int
  start: (int, int)
  grid: Table[Point, char]

func parseSketch(text: string): Sketch =
  let lines = text.strip.splitLines()
  result.rows = lines.len
  result.cols = lines[0].len

  for (r, line) in enumerate(lines):
    for (c, sym) in enumerate(line):
      result.grid[(r, c)] = sym

      if sym == 'S':
        result.start = (r, c)

func pipeAt(s: Sketch, p: Point): char =
  if p.r in 0 ..< s.rows and p.c in 0 ..< s.cols:
    s.grid[p]
  else:
    '.'

type Direction = enum
  N
  S
  E
  W

proc hasConn(s: Sketch, p: Point, d: Direction): bool =
  case s.pipeAt(p):
    of 'S': true
    of '.': false
    of '|': d in [N, S]
    of '-': d in [W, E]
    of 'L': d in [N, E]
    of 'J': d in [N, W]
    of '7': d in [W, S]
    of 'F': d in [E, S]
    else: raise newException(ValueError, $s.grid[p])

func neighbors(s: Sketch, p: Point): seq[Point] =
  for (dr, dc, pDir, nDir) in [
    (-1, 0, N, S), # Up     N-S
    (+1, 0, S, N), # Down   S-N
    (0, -1, W, E), # Left   W-E
    (0, +1, E, W), # Right  E-W
  ]:
    let n = (p.r + dr, p.c + dc)
    if s.hasConn(p, pDir) and s.hasConn(n, nDir):
      result.add(n)

type State = tuple
  point: Point
  distance: int

proc reachable(s: Sketch): Table[Point, int] =
  var queue: Deque[State]
  var seen: HashSet[Point]

  queue.addLast (s.start, 0)

  while queue.len > 0:
    let state = queue.popFirst
    if state.point in seen:
      continue

    result[state.point] = state.distance
    seen.incl state.point

    for n in s.neighbors(state.point):
      queue.addLast (n, state.distance + 1)

proc part1(): int =
  let text = readFile("input/day10.txt")
  let sketch = parseSketch(text)

  for d in values(sketch.reachable):
    result = max(result, d)

echo part1()
