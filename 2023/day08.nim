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

proc dbg[T](v: T): T = (echo(v); v)

proc part1(): int =
  let text = readFile("input/day08.txt")
  var map = parseMap(text)

  var mv = 0
  var loc = "AAA"
  while loc != "ZZZ":
    case map.moves[mv mod len(map.moves)]:
      of L: loc = map.nodes[loc].left
      of R: loc = map.nodes[loc].right
    mv = mv + 1
  return mv

echo part1()
