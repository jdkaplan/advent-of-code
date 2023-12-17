import std/algorithm
import std/deques
import std/enumerate
import std/heapqueue
import std/math
import std/options
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables
import std/terminal
import std/times

proc dbg[T](v: T): T = (echo(v); v)

func empty[T](v: seq[T]): bool = v.len == 0

proc split[T](v: seq[T], pred: proc(elt: T): bool {.noSideEffect.}): seq[seq[T]] =
  var current: seq[T]
  for elt in v:
    if pred(elt):
      result.add current
      current = @[]
    else:
      current.add elt
  result.add current

func join[T](parts: seq[seq[T]], sep: T): seq[T] =
  if parts.len > 0:
    result &= parts[0]

  for part in parts[1..^1]:
    result.add sep
    result &= part

type Point = tuple
  r: int
  c: int

type Map = object
  height: int
  width: int
  grid: Table[Point, int]

func parseMap(text: string): Map =
  let lines = text.strip.splitLines()
  result.height = lines.len
  result.width = lines[0].len

  for (r, line) in enumerate(lines):
    for (c, sym) in enumerate(line):
      result.grid[(r, c)] = sym.int - '0'.int

type Direction = enum
  N
  W
  S
  E

func cw(d: Direction): Direction =
  case d:
    of N: E
    of E: S
    of S: W
    of W: N

func ccw(d: Direction): Direction =
  case d:
    of N: W
    of W: S
    of S: E
    of E: N

func move(p: Point, d: Direction, n: int): Point =
  case d:
    of N: (p.r - n, p.c)
    of S: (p.r + n, p.c)
    of W: (p.r, p.c - n)
    of E: (p.r, p.c + n)

func inBounds(m: Map, p: Point): bool =
  p.r in 0 ..< m.height and p.c in 0 ..< m.width

func loss(m: Map, p: Point): int =
  if m.inBounds(p):
    return m.grid[p]

type State = tuple
  pos: Point
  dir: Direction

type Node = tuple
  state: State
  cost: int

func `<`(a, b: Node): bool = a.cost < b.cost


iterator successors(m: Map, state: State): (State, int) =
  for steps in 1..3:
    var pos = state.pos
    var loss = 0
    for _ in 1..steps:
      pos = pos.move(state.dir, 1)
      loss += m.loss(pos)

    yield ((pos, state.dir.cw), loss)
    yield ((pos, state.dir.ccw), loss)

proc heatLoss(m: Map, start, goal: Point): int =
  var queue: HeapQueue[Node]
  var seen: HashSet[State]

  # Unknown starting direction, so try them all.
  queue.push ((start, N), 0)
  queue.push ((start, S), 0)
  queue.push ((start, E), 0)
  queue.push ((start, W), 0)

  while queue.len > 0:
    let (state, cost) = queue.pop

    if not m.inBounds(state.pos): continue

    if state in seen: continue
    seen.incl state

    if state.pos == goal:
      return cost

    for (next, extra) in m.successors(state):
      queue.push (next, cost + extra)

proc part1(input: string): int =
  let text = readFile(input)
  let map = parseMap(text)
  map.heatLoss((0, 0), (map.height - 1, map.width - 1))

proc timed[T](f: () -> T): T =
  let start = cpuTime()
  result = f()
  echo "Time :", cpuTime() - start

echo timed(proc(): int = part1("input/test.txt"))
echo timed(proc(): int = part1("input/day17.txt"))
