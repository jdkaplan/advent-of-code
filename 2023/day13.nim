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

proc reflectAtV(p: Pattern, c: int): bool =
  for dc in 0 .. c:
    let (l, okL) = p.col(c-dc - 1)
    let (r, okR) = p.col(c+dc)
    if okL and okR and l != r:
      return false
  true

proc reflectAtH(p: Pattern, r: int): bool =
  for dr in 0 ..< r:
    let (u, okU) = p.row(r-dr - 1)
    let (d, okD) = p.row(r+dr)
    if okU and okD and d != u:
      return false
  true

proc reflectVertical(p: Pattern): int =
  for c in 1 ..< p.width:
    if p.reflectAtV(c):
      return c

proc reflectHorizontal(p: Pattern): int =
  for r in 1 ..< p.height:
    if p.reflectAtH(r):
      return r

proc part1(input: string): int =
  let text = readFile(input)
  let patterns = parsePatterns(text)

  for pattern in patterns:
    result.inc pattern.reflectVertical
    result.inc 100 * pattern.reflectHorizontal

echo part1("input/test.txt")
echo part1("input/day13.txt")
