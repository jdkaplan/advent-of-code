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

type Platform = object
  height: int
  width: int

  rows: seq[seq[char]]
  cols: seq[seq[char]]

func parsePlatform(text: string): Platform =
  let lines = text.strip.splitLines()
  result.height = lines.len
  result.width = lines[0].len

  for r in 0 ..< result.height:
    result.rows.add @[]

  for c in 0 ..< result.width:
    result.cols.add @[]

  for (r, line) in enumerate(lines):
    for (c, sym) in enumerate(line):
      result.rows[r] &= @[sym]
      result.cols[c] &= @[sym]

func render(p: Platform): string =
  p.rows.mapIt(it.mapIt($it).join("")).join("\n")

proc fromCols(cols: seq[seq[char]]): Platform =
  result.cols = cols
  result.width = cols.len
  result.height = cols[0].len

  for r in 0 ..< result.height:
    result.rows.add @[]

  for (c, col) in enumerate(cols):
    for (r, sym) in enumerate(col):
      result.rows[r] &= @[sym]

proc fromRows(rows: seq[seq[char]]): Platform =
  result.rows = rows
  result.height = rows.len
  result.width = rows[0].len

  for c in 0 ..< result.width:
    result.cols.add @[]

  for (r, row) in enumerate(rows):
    for (c, sym) in enumerate(row):
      result.cols[c] &= @[sym]

func tilt(rocks: seq[char], order: SortOrder): seq[char] =
  let parts = rocks.split(func (sym: char): bool = sym == '#')
  var rolled: seq[seq[char]]
  for part in parts:
    rolled.add part.sorted(order)
  result = rolled.join('#')

func tiltCols(p: Platform, order: SortOrder): Platform =
  var cols: seq[seq[char]]
  for col in p.cols:
    cols.add col.tilt(order)
  fromCols(cols)

func tiltRows(p: Platform, order: SortOrder): Platform =
  var rows: seq[seq[char]]
  for row in p.rows:
    rows.add row.tilt(order)
  fromRows(rows)

func tiltNorth(p: Platform): Platform =
  p.tiltCols(Descending)

func tiltSouth(p: Platform): Platform =
  p.tiltCols(Ascending)

func tiltWest(p: Platform): Platform =
  p.tiltRows(Descending)

func tiltEast(p: Platform): Platform =
  p.tiltRows(Ascending)

type Direction = enum
  N
  S
  E
  W

func tilt(p: Platform, d: Direction): Platform =
  case d:
    of N: p.tiltNorth
    of S: p.tiltSouth
    of E: p.tiltEast
    of W: p.tiltWest

proc loadNorth(platform: Platform): int =
  for (r, row) in enumerate(platform.rows):
    for sym in row:
      if sym != 'O': continue
      result.inc (platform.height - r)

proc part1(input: string): int =
  let text = readFile(input)
  let platform = parsePlatform(text)
  platform.tiltNorth.loadNorth

func cycle(p: Platform): Platform =
  p.tiltNorth.tiltWest.tiltSouth.tiltEast

type Loop = tuple
  start: int
  stop: int
  length: int

proc findLoop(p: Platform): (Loop, Platform) =
  let cycle = @[N, W, S, E]

  var seen: Table[Platform, int]
  seen[p] = 0

  var p = p
  var i = 0
  while true:
    inc i

    for dir in cycle:
      p = p.tilt(dir)

    if p in seen:
      let start = seen[p]
      return ((start, i, i - start), p)
    seen[p] = i

proc part2(input: string): int =
  let text = readFile(input)
  let platform = parsePlatform(text)
  let cycles = 1_000_000_000

  let (loop, state) = platform.findLoop

  let repeats = (cycles - loop.stop).floorDiv(loop.length)
  let timeSkip = loop.stop + repeats * loop.length
  let remaining = cycles - timeSkip

  var p = state
  for _ in 0 ..< remaining:
    p = p.cycle
  p.loadNorth

echo part1("input/test.txt")
echo part1("input/day14.txt")
echo part2("input/test.txt")
echo part2("input/day14.txt")
