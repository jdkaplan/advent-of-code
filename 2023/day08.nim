import std/algorithm
import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables

type Move {.pure.} = enum
  L
  R

proc parseMove(c: char): Move =
  case c:
    of 'L': L
    of 'R': R
    else: raise newException(ValueError, $c)

func parseMoves(line: string): seq[Move] =
  line.map(parseMove)

type Node = object
  id: string
  left: string
  right: string

proc parseNode(line: string): Node =
  if not scanf(line, "$+ = ($+, $+)$.", result.id, result.left, result.right):
    raise newException(ValueError, line)

type Map = object
  moves: seq[Move]
  nodes: Table[string, Node]

proc parseMap(text: string): Map =
  let parts = text.strip.split("\n\n")
  result.moves = parts[0].parseMoves
  for node in parts[1].strip.splitLines.map(parseNode):
    result.nodes[node.id] = node

func step(map: Map, loc: string, n: int): string =
  case map.moves[n mod len(map.moves)]:
    of L: map.nodes[loc].left
    of R: map.nodes[loc].right

proc dbg[T](v: T): T = (echo(v); v)

proc part1(): int =
  let text = readFile("input/day08.txt")
  var map = parseMap(text)

  var loc = "AAA"
  while loc != "ZZZ":
    loc = map.step(loc, result)
    inc result

func isDone(loc: string): bool =
  loc.endsWith('Z')

func walk(map: Map, start: string): seq[int] =
  var loc = start
  var mv = 0
  while true:
    if loc.isDone:
      result.add mv
      if result.len > 2:
        if result[^1] - result[^2] == result[^2] - result[^3]:
          return
    loc = map.step(loc, mv)
    inc mv

func gcd(a: int, b: int): int =
  var a = a
  var b = b
  while b != 0:
    let t = b
    b = a mod b
    a = t
  return a

func gcd(nums: seq[int]): int =
  result = gcd(nums[0], nums[1])
  for n in nums[2..^1]:
    result = gcd(result, n)

proc part2(): int =
  let text = readFile("input/day08.txt")
  var map = parseMap(text)

  var starts: seq[string]
  for loc in map.nodes.keys:
    if loc.endsWith('A'):
      starts.add loc

  var periods: seq[int]
  for start in starts:
    let times = map.walk(start)
    assert(3 * times[0] == times[2])
    periods.add times[0]

  let gcd = gcd(periods)

  result = periods[0]
  for p in periods[1..^1]:
    result *= int(p / gcd)

echo part1()
echo part2()
