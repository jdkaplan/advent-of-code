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

###################

type Pulse = enum
  High
  Low

# Something about how I'm defining these objects and methods is very wrong.
#
# Depending on how much of `pushButton` I implement, I either get a type
# mismatch when trying to resolve `mm.send()` below or an error message from
# `gcc` about `Sup` in something that is not a structure or a union.
#
# Neither of these seem like fun to debug right now.

type
  Module = ref object of RootObj
    name: string
    dests: seq[string]
  Broadcaster = ref object of Module
  FlipFlop = ref object of Module
    state: Pulse
  Conjunction = ref object of Module
    state: Table[string, Pulse]

func parseModule(line: string): Module =
  let parts = line.strip.split(" -> ", 1)
  let (name, dests) = (parts[0], parts[1])

  result.dests = dests.split(", ")

  if name[0] == '%':
    result = FlipFlop(name: name[1..^1], state: Low)
  elif name[0] == '&':
    result = Conjunction(name: name[1..^1])
  elif name == "broadcaster":
    result = Broadcaster(name: name)
  else:
    raise newException(ValueError, line)

type Machine = tuple
  modules: Table[string, Module]

func newMachine(text: string): Machine =
  for m in text.strip.splitLines.map(parseModule):
    result.modules[m.name] = m

  for (srcName, srcMod) in result.modules.pairs:
    for dstName in srcMod.dests:
      let dstMod = result.modules[dstName]
      if typeof(dstMod) is Conjunction:
        Conjunction(dstMod).state[srcName] = Low

type Wire = tuple
  src: string
  dest: string
  value: Pulse

method send(m: ref var Module, source: string, p: Pulse): seq[Wire] {.base.} =
  raise newException(CatchableError, "abstract method")

method send(b: ref var Broadcaster, _: string, p: Pulse): seq[Wire] =
  let src = b.name
  for dst in b.dests:
    result.add (src, dst, p)

method send(c: ref var Conjunction, source: string, p: Pulse): seq[Wire] =
  c.state[source] = p

  var output = Low
  for v in c.state.values:
    if v == Low:
      output = High
      break

  let src = c.name
  for dst in c.dests:
    result.add (src, dst, output)

method send(f: ref var FlipFlop, source: string, p: Pulse): seq[Wire] =
  if p == High:
    return @[]

  var output = Low
  case f.state:
    of High:
      f.state = Low
      output = Low
    of Low:
      f.state = High
      output = High

  let src = f.name
  for dst in f.dests:
    result.add (src, dst, output)

proc pushButton(m: var Machine): CountTable[Pulse] =
  var queue: Deque[Wire]

  queue.addLast ("button", "broadcaster", Low)

  while queue.len > 0:
    let (src, name, pulse) = queue.popFirst
    result.inc pulse

    let mm = m.modules[name]
    echo typeof(mm)
    for output in mm.send(src, pulse):
      queue.addLast output

proc part1(input: string): int =
  let text = readFile(input)
  var machine = newMachine(text)

  let pulses = machine.pushButton
  pulses[High] * pulses[Low]

###################

proc timed[T](f: () -> T): T =
  let start = cpuTime()
  result = f()
  echo "Time :", cpuTime() - start

echo timed(proc(): int = part1("input/test.txt"))
# echo timed(proc(): int = part1("input/day20.txt"))
# echo timed(proc(): int = part2("input/test.txt"))
# echo timed(proc(): int = part2("input/day20.txt"))
