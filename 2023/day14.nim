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

proc split[T](v: seq[T], pred: proc(elt: T): bool): seq[seq[T]] =
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

  grid: Table[Point, char]

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
      result.grid[(r, c)] = sym
      result.rows[r] &= @[sym]
      result.cols[c] &= @[sym]

proc fromCols(cols: seq[seq[char]]): Platform =
  result.cols = cols
  result.width = cols.len
  result.height = cols[0].len

  for r in 0 ..< result.height:
    result.rows.add @[]

  for (c, col) in enumerate(cols):
    for (r, sym) in enumerate(col):
      result.grid[(r, c)] = sym
      result.rows[r] &= @[sym]

func render(p: Platform): string =
  p.rows.mapIt(it.mapIt($it).join("")).join("\n")

proc tiltNorth(col: seq[char]): seq[char] =
  let parts = col.split(func (sym: char): bool = sym == '#')
  var rolled: seq[seq[char]]
  for part in parts:
    rolled.add part.sorted(Descending)
  result = rolled.join('#')

proc tiltNorth(p: Platform): Platform =
  var cols: seq[seq[char]]
  for col in p.cols:
    cols.add col.tiltNorth
  fromCols(cols)

proc loadNorth(platform: Platform): int =
  for (p, sym) in platform.grid.pairs:
    if sym != 'O': continue
    result.inc (platform.height - p.r)

proc part1(input: string): int =
  let text = readFile(input)
  let platform = parsePlatform(text)
  platform.tiltNorth.loadNorth

echo part1("input/test.txt")
echo part1("input/day14.txt")
# echo part2("input/test.txt")
# echo part2("input/day14.txt")
