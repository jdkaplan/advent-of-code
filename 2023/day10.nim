import std/algorithm
import std/deques
import std/enumerate
import std/math
import std/options
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables
import std/terminal

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

func inBounds(s: Sketch, p: Point): bool =
  p.r in 0 ..< s.rows and p.c in 0 ..< s.cols

func pipeAt(s: Sketch, p: Point): char =
  if s.inBounds(p):
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
    if not s.inBounds(n):
      continue
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

  let reachable = sketch.reachable
  for d in values(reachable):
    result = max(result, d)

proc path(s: Sketch): seq[Point] =
  var queue: Deque[seq[Point]]

  queue.addLast @[s.start]

  while queue.len > 0:
    let path = queue.popFirst
    let point = path[^1]

    if path.len > 1 and s.pipeAt(point) == 'S':
      return path

    for n in s.neighbors(point):
      if path.len > 1 and path[^2] == n:
        continue
      queue.addLast(path & @[n])

func inBoundsPadding(s: Sketch, p: Point): bool =
  p.r in -1 .. s.rows and p.c in -1 .. s.cols

func neighborsFill(s: Sketch, p: Point): seq[Point] =
  for (dr, dc) in [
    (-1, 0), # Up
    (+1, 0), # Down
    (0, -1), # Left
    (0, +1), # Right
  ]:
    let n = (p.r + dr, p.c + dc)
    if s.inBoundsPadding(n):
      result.add n

proc floodFill(s: Sketch, start: Point, path: HashSet[Point]): HashSet[Point] =
  var queue: Deque[Point]

  queue.addLast start

  while queue.len > 0:
    let state = queue.popFirst

    if state in result:
      continue
    result.incl state

    for n in s.neighborsFill(state):
      if n in path:
        continue
      queue.addLast n

func cells(s: Sketch): HashSet[Point] =
  for r in 0 ..< s.rows:
    for c in 0 ..< s.cols:
      result.incl (r, c)

proc heading(a: Point, b: Point): Direction =
  let dr = b.r - a.r
  let dc = b.c - a.c
  assert(abs(dr) + abs(dc) == 1)

  if dr == -1: return N
  if dr == +1: return S
  if dc == -1: return W
  if dc == +1: return E
  assert(false)

func north(p: Point): Point = (p.r - 1, p.c)
func south(p: Point): Point = (p.r + 1, p.c)
func east(p: Point): Point =  (p.r   , p.c + 1)
func west(p: Point): Point =  (p.r   , p.c - 1)

func northwest(p: Point): Point = (p.r - 1, p.c - 1)
func northeast(p: Point): Point = (p.r - 1, p.c + 1)
func southwest(p: Point): Point = (p.r + 1, p.c - 1)
func southeast(p: Point): Point = (p.r + 1, p.c + 1)

func sides3(p: Point, h: Direction): (seq[Point], seq[Point]) =
  case h:
    of N: (
      @[p.northwest, p.west, p.southwest],
      @[p.northeast, p.east, p.southeast],
    )
    of S: (
      @[p.southeast, p.east, p.northeast],
      @[p.southwest, p.west, p.northwest],
    )
    of E: (
      @[p.northeast, p.north, p.northwest],
      @[p.southeast, p.south, p.southwest],
    )
    of W: (
      @[p.southwest, p.south, p.southeast],
      @[p.northwest, p.north, p.northeast],
    )

func sides2(p: Point, h: Direction): (seq[Point], seq[Point]) =
  let (l, r) = sides3(p, h)
  (l[0..^2], r[0..^2])

proc walkPath(s: Sketch, path: seq[Point]): (HashSet[Point], HashSet[Point]) =
  for (a, b) in zip(path[0..^2], path[1..^1]):
    let h = a.heading(b)

    let (left, right) = sides2(a, h)
    for p in left:
      result[0].incl p
    for p in right:
      result[1].incl p

type Side = enum
  Left
  Right

func whichSide(p: Point, left: HashSet[Point], right: HashSet[Point]): Option[Side] =
  if p in left and p in right:
    return none(Side)
  if p in left:
    return some(Left)
  if p in right:
    return some(Right)
  return none(Side)

proc part2(): int =
  let text = readFile("input/day10.txt")
  let sketch = parseSketch(text)

  let path = sketch.path
  assert sketch.pipeAt(path[0]) == 'S'
  assert sketch.pipeAt(path[^1]) == 'S'

  let (left, right) = sketch.walkPath(path)

  var candidates = sketch.cells

  let pathSet = path.toHashSet
  for p in pathSet:
    candidates.excl p

  var foundOutsideSide = false
  var outside: Side
  for p in sketch.floodFill((-1, -1), pathSet):
    candidates.excl p

    if p in pathSet:
      continue

    # Marked both ways, inconclusve?
    if p in left and p in right:
      continue

    if p in left:
      if foundOutsideSide:
        assert(outside == Left)
      foundOutsideSide = true
      outside = Left
    elif p in right:
      if foundOutsideSide:
        assert(outside == Right)
      foundOutsideSide = true
      outside = Right

  var inside: HashSet[Point]
  for r in 0 ..< sketch.rows:
    for c in 0 ..< sketch.cols:
      let p = (r, c)

      # Already known to be outside or on path
      if p notin candidates:
        continue

      let s = whichSide(p, left, right)
      if s.isSome and s.get == outside:
        for pOut in sketch.floodFill(p, pathSet):
          candidates.excl pOut
      elif s.isSome and s.get != outside:
        for pIn in sketch.floodFill(p, pathSet):
          inside.incl pIn
      else:
        discard "Inconclusive! I hope this doesn't matter!"

  assert(candidates.len == inside.len)
  inside.len

echo part1()
echo part2()
