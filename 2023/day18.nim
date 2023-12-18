import std/algorithm
import std/bitops
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

type Instruction = tuple
  dir: Direction
  steps: int
  color: int

func parseInstruction(line: string): Instruction =
  var dir: string
  if not scanf(line, "$+ $i (#$h)$.", dir, result.steps, result.color):
    raise newException(ValueError, line)
  result.dir = dir.parseDirection

func parseInstructions(text: string): seq[Instruction] =
  text.strip.splitLines.map(parseInstruction)

type Point = tuple
  r: int
  c: int

func `$`(p: Point): string = "(" & $p.r & ", " & $p.c & ")"

func move(p: Point, d: Direction, n: int): Point =
  case d:
    of N: (p.r - n, p.c)
    of S: (p.r + n, p.c)
    of W: (p.r, p.c - n)
    of E: (p.r, p.c + n)

func fix(i: Instruction): Instruction =
  let steps = i.color shr 4
  let dir = case i.color.masked 0xf
    of 0: "R"
    of 1: "D"
    of 2: "L"
    of 3: "U"
    else: raise newException(ValueError, $i.color)
  (dir.parseDirection, steps, i.color)

func `//`(a, b: int): int =
  assert a mod b == 0
  a.floorDiv(b)

func polygon(path: seq[Instruction]): seq[Point] =
  var pos = (0, 0)
  result.add pos

  for i in path:
    pos = pos.move(i.dir, i.steps)
    result.add pos

proc area(path: seq[Point]): int =
  for i in 0 ..< path.len - 1:
    let a = path[i]
    let b = path[(i+1) mod path.len]

    let area = a.r * b.c - b.r * a.c
    result.inc area
    # echo a, " ", b, " = ", area, " => ", result

func axisAligned(a, b: Point): bool =
  a.r == b.r or a.c == b.c

func distance(a, b: Point): int =
  abs(b.r - a.r) + abs(b.c - a.c)

proc distance(path: seq[Point]): int =
  for i in 0 ..< path.len - 1:
    let a = path[i]
    let b = path[(i+1) mod path.len]
    assert axisAligned(a, b)

    let len = distance(a, b)
    result.inc len

func lagoonArea(ii: seq[Instruction]): int =
  let path = polygon(ii)
  (path.area // 2).abs + (path.distance // 2) + 1

proc part1(input: string): int =
  let text = readFile(input)
  let instructions = parseInstructions(text)
  lagoonArea(instructions)

proc part2(input: string): int =
  let text = readFile(input)
  let instructions = parseInstructions(text)
  lagoonArea(instructions.map(fix))

###################

proc timed[T](f: () -> T): T =
  let start = cpuTime()
  result = f()
  echo "Time :", cpuTime() - start

echo timed(proc(): int = part1("input/test.txt"))
echo timed(proc(): int = part1("input/day18.txt"))
echo timed(proc(): int = part2("input/test.txt"))
echo timed(proc(): int = part2("input/day18.txt"))
