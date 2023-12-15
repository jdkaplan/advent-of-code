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

type Init = tuple
  steps: seq[string]

func parseInit(text: string): Init =
  result.steps = text.strip.split(',')

func hash(step: string): int =
  for c in step:
    result = ((result + c.ord) * 17) mod 256

proc part1(input: string): int =
  let text = readFile(input)
  let init = parseInit(text)

  init.steps.map(hash).sum

echo part1("input/test.txt")
echo part1("input/day15.txt")
