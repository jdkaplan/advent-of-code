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

type Point = tuple
  r: int
  c: int

type Pattern = object
  height: int
  width: int

  grid: Table[Point, char]

  rows: seq[seq[char]]
  cols: seq[seq[char]]

func parsePattern(text: string): Pattern =
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

func parsePatterns(text: string): seq[Pattern] =
  text.strip.split("\n\n").map(parsePattern)

func col(p: Pattern, c: int): (seq[char], bool) =
  if c in p.cols.low .. p.cols.high:
    (p.cols[c], true)
  else:
    (@[], false)

func row(p: Pattern, r: int): (seq[char], bool) =
  if r in p.rows.low .. p.rows.high:
    (p.rows[r], true)
  else:
    (@[], false)

func diff(a: seq[char], b: seq[char]): seq[int] =
  for (aa, bb) in zip(a, b):
    if aa != bb:
      result.add 1

func distance(a: seq[char], b: seq[char]): int =
  diff(a, b).sum

func reflectDistanceV(p: Pattern, c: int): int =
  for dc in 0 .. c:
    let (l, okL) = p.col(c-dc - 1)
    let (r, okR) = p.col(c+dc)
    if okL and okR:
      result.inc distance(l, r)

func reflectDistanceH(p: Pattern, r: int): int =
  for dr in 0 ..< r:
    let (u, okU) = p.row(r-dr - 1)
    let (d, okD) = p.row(r+dr)
    if okU and okD:
      result.inc distance(u, d)

proc reflectVertical(p: Pattern): int =
  for c in 1 ..< p.width:
    if p.reflectDistanceV(c) == 0:
      return c

proc reflectHorizontal(p: Pattern): int =
  for r in 1 ..< p.height:
    if p.reflectDistanceH(r) == 0:
      return r

proc fix(p: Pattern): int =
  let cols = (0 ..< p.width ).toSeq.filterIt(p.reflectDistanceV(it) == 1)
  let rows = (0 ..< p.height).toSeq.filterIt(p.reflectDistanceH(it) == 1)
  assert cols.len + rows.len == 1

  if cols.len > 0:
    result.inc cols[0]
  if rows.len > 0:
    result.inc 100 * rows[0]

proc part1(input: string): int =
  let text = readFile(input)
  let patterns = parsePatterns(text)

  for pattern in patterns:
    result.inc pattern.reflectVertical
    result.inc 100 * pattern.reflectHorizontal

proc part2(input: string): int =
  let text = readFile(input)
  let patterns = parsePatterns(text)

  patterns.map(fix).sum

echo part1("input/test.txt")
echo part1("input/day13.txt")
echo part2("input/test.txt")
echo part2("input/day13.txt")
