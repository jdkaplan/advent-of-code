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

type Op = enum
  Dash
  Equals

func parseOp(c: char): Op =
  case c:
    of '-': Dash
    of '=': Equals
    else: result

type Step = tuple
  text: string

  label: string
  op: Op
  num: int

func parseStep(text: string): Step =
  result.text = text

  if scanf(text, "$+=$i$.", result.label, result.num):
    result.op = Equals
    return

  if scanf(text, "$+-$.", result.label):
    result.op = Dash
    return

type Init = tuple
  steps: seq[Step]

func parseInit(text: string): Init =
  result.steps = text.strip.split(',').map(parseStep)

func hash(text: string): int =
  for c in text:
    result = ((result + c.ord) * 17) mod 256

proc part1(input: string): int =
  let text = readFile(input)
  let init = parseInit(text)

  init.steps.mapIt(it.text.hash).sum

type HASHMAP = object
  boxes: array[0..255, OrderedTable[string, int]]

func remove(h: var HASHMAP, label: string) =
  let box = label.hash
  h.boxes[box].del label

func insert(h: var HASHMAP, label: string, focusLength: int) =
  var box = label.hash
  h.boxes[box][label] = focusLength

func exec(h: var HASHMAP, step: Step) =
  case step.op:
    of Dash: h.remove(step.label)
    of Equals: h.insert(step.label, step.num)

func power(h: HASHMAP): int =
  for (i, box) in enumerate(h.boxes):
    for (j, focalLength) in enumerate(box.values):
      result.inc (i + 1) * (j + 1) * focalLength

proc part2(input: string): int =
  let text = readFile(input)
  let init = parseInit(text)

  var hashmap: HASHMAP
  for step in init.steps:
    hashmap.exec step
  hashmap.power

echo part1("input/test.txt")
echo part1("input/day15.txt")
echo part2("input/test.txt")
echo part2("input/day15.txt")
