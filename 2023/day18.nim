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

type Direction = enum
  N
  W
  S
  E

func parseDirection(s: string): Direction =
  case s:
    of "U": N
    of "D": S
    of "L": W
    of "R": E
    else:
      raise newException(ValueError, s)

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

type Instruction = tuple
  dir: Direction
  steps: int
  color: string

func parseInstruction(line: string): Instruction =
  var dir: string
  if not scanf(line, "$+ $i ($+)$.", dir, result.steps, result.color):
    raise newException(ValueError, line)
  result.dir = dir.parseDirection

func parseInstructions(text: string): seq[Instruction] =
  text.strip.splitLines.map(parseInstruction)

type Point = tuple
  r: int
  c: int

func move(p: Point, d: Direction, n: int): Point =
  case d:
    of N: (p.r - n, p.c)
    of S: (p.r + n, p.c)
    of W: (p.r, p.c - n)
    of E: (p.r, p.c + n)

type Lagoon = object
  grid: Table[Point, char]

  rlo, rhi: int
  clo, chi: int

func assign(l: var Lagoon, p: Point, sym: char) =
  l.grid[p] = sym

  l.rlo = min(l.rlo, p.r)
  l.rhi = max(l.rhi, p.r)
  l.clo = min(l.clo, p.c)
  l.chi = max(l.chi, p.c)

func dig(l: var Lagoon, p: Point) =
  l.assign(p, '#')

func inBoundsPadding(l: Lagoon, p: Point): bool =
  p.r in (l.rlo - 1) .. (l.rhi + 1) and p.c in (l.clo - 1) .. (l.chi + 1)

func neighborsFill(l: Lagoon, p: Point): seq[Point] =
  for (dr, dc) in [
    (-1, 0), # Up
    (+1, 0), # Down
    (0, -1), # Left
    (0, +1), # Right
  ]:
    let n = (p.r + dr, p.c + dc)
    if l.inBoundsPadding(n):
      result.add n

proc floodFill(l: var Lagoon, start: Point, sym: char) =
  var queue: Deque[Point]

  queue.addLast start

  while queue.len > 0:
    let p = queue.popFirst

    if p in l.grid: continue
    l.grid[p] = sym

    for n in l.neighborsFill(p):
      queue.addLast n

proc fill(l: var Lagoon) =
  let empty = (l.rlo - 1, l.clo - 1)
  l.floodFill(empty, '.')

  for r in l.rlo .. l.rhi:
    for c in l.clo .. l.chi:
      let p = (r, c)
      if p notin l.grid:
        l.dig(p)

func execute(l: var Lagoon, instructions: seq[Instruction]) =
  var pos: Point = (0, 0)
  l.dig(pos)

  for i in instructions:
    for _ in 1 .. i.steps:
      pos = pos.move(i.dir, 1)
      l.dig(pos)

func render(l: Lagoon): string =
  for r in l.rlo .. l.rhi:
    for c in l.clo .. l.chi:
      result &= l.grid.getOrDefault((r, c), ' ')
    result &= '\n'

func countDug(l: Lagoon): int =
  for r in l.rlo .. l.rhi:
    for c in l.clo .. l.chi:
      if l.grid[(r, c)] == '#':
        result.inc

proc part1(input: string): int =
  let text = readFile(input)
  let instructions = parseInstructions(text)

  var lagoon: Lagoon
  lagoon.execute(instructions)
  lagoon.fill
  lagoon.countDug

###################

proc timed[T](f: () -> T): T =
  let start = cpuTime()
  result = f()
  echo "Time :", cpuTime() - start

echo timed(proc(): int = part1("input/test.txt"))
echo timed(proc(): int = part1("input/day18.txt"))
