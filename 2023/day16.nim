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

type Contraption = object
  height: int
  width: int
  grid: Table[Point, char]

func parseContraption(text: string): Contraption =
  let lines = text.strip.splitLines()
  result.height = lines.len
  result.width = lines[0].len

  for (r, line) in enumerate(lines):
    for (c, sym) in enumerate(line):
      result.grid[(r, c)] = sym

type Direction = enum
  N
  W
  S
  E

func move(p: Point, d: Direction): Point =
  case d:
    of N: (p.r - 1, p.c)
    of S: (p.r + 1, p.c)
    of W: (p.r, p.c - 1)
    of E: (p.r, p.c + 1)

type Beam = tuple
  pos: Point
  dir: Direction

func tick(c: Contraption, beam: Beam): seq[Beam] =
  let (pos, dir) = beam
  let tile = c.grid[beam.pos]
  case tile:
    of '.': @[(pos.move(dir), dir)]
    of '/':
      case dir:
        of N: @[(pos.move(E), E)]
        of E: @[(pos.move(N), N)]
        of S: @[(pos.move(W), W)]
        of W: @[(pos.move(S), S)]
    of '\\':
      case dir:
        of N: @[(pos.move(W), W)]
        of W: @[(pos.move(N), N)]
        of S: @[(pos.move(E), E)]
        of E: @[(pos.move(S), S)]
    of '|':
      case dir:
        of N: @[(pos.move(dir), dir)]
        of S: @[(pos.move(dir), dir)]
        of W: @[(pos.move(N), N), (pos.move(S), S)]
        of E: @[(pos.move(N), N), (pos.move(S), S)]
    of '-':
      case dir:
        of W: @[(pos.move(dir), dir)]
        of E: @[(pos.move(dir), dir)]
        of N: @[(pos.move(E), E), (pos.move(W), W)]
        of S: @[(pos.move(E), E), (pos.move(W), W)]
    else:
      raise newException(ValueError, $tile)

func inBounds(c: Contraption, p: Point): bool =
  p.r in 0 ..< c.height and p.c in 0 ..< c.width

func inBounds(c: Contraption, b: Beam): bool =
  c.inBounds(b.pos)

func run(c: Contraption, start: Beam): HashSet[Point] =
  var beams: Deque[Beam]
  var seen: HashSet[Beam]

  beams.addFirst start
  while beams.len > 0:
    let beam = beams.popFirst
    if not c.inBounds(beam):
      continue
    if beam in seen:
      continue
    seen.incl beam

    for next in c.tick(beam):
      beams.addLast next

  seen.map(func (b: Beam): Point = b.pos)

proc part1(input: string): int =
  let text = readFile(input)
  let contraption = parseContraption(text)
  contraption.run(((0, 0), E)).len

proc part2(input: string): int =
  let text = readFile(input)
  let contraption = parseContraption(text)

  # North edge
  for c in 0 ..< contraption.width:
    let tiles = contraption.run ((0, c), S)
    result = result.max(tiles.len)

  # South edge
  for c in 0 ..< contraption.width:
    let tiles = contraption.run ((contraption.height - 1, c), N)
    result = result.max(tiles.len)

  # West edge
  for r in 0 ..< contraption.height:
    let tiles = contraption.run ((r, 0), E)
    result = result.max(tiles.len)

  # East edge
  for r in 0 ..< contraption.height:
    let tiles = contraption.run ((r, contraption.width - 1), W)
    result = result.max(tiles.len)

echo part1("input/test.txt")
echo part1("input/day16.txt")
echo part2("input/test.txt")
echo part2("input/day16.txt")
