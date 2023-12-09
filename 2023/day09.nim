import std/algorithm
import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables

proc dbg[T](v: T): T = (echo(v); v)

type History = seq[int]

func parseHistory(line: string): History =
  line.strip.splitWhitespace.map(parseInt)

func allZero(h: History): bool =
  h.allIt(it == 0)

func diff(h: History): History =
  for (i, j) in zip(h[0..^1], h[1..^1]):
    result.add(j - i)

func deduce(h: History): seq[History] =
  result.add h

  var h = h
  while not h.allZero:
    h = h.diff
    result.add h

type Histories = seq[History]

func parseHistories(text: string): Histories =
  text.strip.splitLines.map(parseHistory)

func extrapolate(hs: var Histories): seq[int] =
  assert(hs[^1][^1] == 0)

  var row = len(hs) - 1
  result.add 0
  hs[row].add 0

  while row > 0:
    let inferred = hs[row-1][^1] + hs[row][^1]
    result.add inferred
    hs[row-1].add inferred
    dec row

proc part1(): int =
  let text = readFile("input/day09.txt")
  var histories = parseHistories(text)

  for h in histories:
    var hh = deduce(h)
    result.inc extrapolate(hh)[^1]

echo part1()
