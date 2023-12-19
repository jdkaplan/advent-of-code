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

type Op = enum
  None
  Lt
  Gt

func parseOp(c: char): Op =
  case c:
    of '<': Lt
    of '>': Gt
    else: raise newException(ValueError, $c)

type Step = tuple
  attr: char
  op: Op
  val: int
  dest: string

func parseStep(text: string): Step =
  var op: char
  if scanf(text, "$c$c$i:$+$.", result.attr, op, result.val, result.dest):
    result.op = op.parseOp
    return

  if scanf(text, "$w$.", result.dest):
    result.op = None
    return

  raise newException(ValueError, text)

type Workflow = tuple
  name: string
  steps: seq[Step]

func parseWorkflow(text: string): Workflow =
  var steps: string
  if not scanf(text, "$+{$+}$.", result.name, steps):
    raise newException(ValueError, text)
  result.steps = steps.split(',').map(parseStep)

type Part = tuple
  attrs: Table[char, int]

func parseAttr(text: string): (char, int) =
  if not scanf(text, "$c=$i$.", result[0], result[1]):
    raise newException(ValueError, text)

func parseAttrs(text: string): Table[char, int] =
  for (a, v) in text.split(',').map(parseAttr):
    result[a] = v

func parsePart(line: string): Part =
  var attrs: string
  if not scanf(line, "{$+}$.", attrs):
    raise newException(ValueError, line)
  result.attrs = attrs.parseAttrs

type System = tuple
  workflows: Table[string, Workflow]
  parts: seq[Part]

func parseSystem(text: string): System =
  let sections = text.split("\n\n")
  assert sections.len == 2

  for w in sections[0].strip.splitLines.map(parseWorkflow):
    result.workflows[w.name] = w

  result.parts = sections[1].strip.splitLines.map(parsePart)

func apply(w: Workflow, p: Part): string =
  for s in w.steps:
    case s.op:
      of None:
        return s.dest
      of Lt:
        if p.attrs[s.attr] < s.val:
          return s.dest
      of Gt:
        if p.attrs[s.attr] > s.val:
          return s.dest

func accepted(sys: System, part: Part): bool =
  var w = "in"
  while w != "R" and w != "A":
    w = sys.workflows[w].apply(part)
  w == "A"

func rating(p: Part): int =
  for v in p.attrs.values:
    result.inc v

proc part1(input: string): int =
  let text = readFile(input)
  let system = parseSystem(text)

  for part in system.parts:
    if system.accepted(part):
      result.inc part.rating

type Range = tuple
  lo, hi: int

func maxRange(): Range = (1, 4000)

type Ranges = tuple
  x, m, a, s: Range

func maxRanges(): Ranges =
  result.x = maxRange()
  result.m = maxRange()
  result.a = maxRange()
  result.s = maxRange()

func minRanges(): Ranges = result

func splitLt(r: Range, v: int): (Range, Range) =
  ((r.lo, v - 1), (v, r.hi))

func splitGt(r: Range, v: int): (Range, Range) =
  ((r.lo, v), (v + 1, r.hi))

func keepLt(r: Range, v: int): Range = splitLt(r, v)[0]
func keepGt(r: Range, v: int): Range = splitGt(r, v)[1]
func dropLt(r: Range, v: int): Range = splitLt(r, v)[1]
func dropGt(r: Range, v: int): Range = splitGt(r, v)[0]

func keep(rr: Range, step: Step): Range =
  case step.op:
    of None: rr
    of Lt: rr.keepLt(step.val)
    of Gt: rr.keepGt(step.val)

func drop(rr: Range, step: Step): Range =
  case step.op:
    of None: rr
    of Lt: rr.dropLt(step.val)
    of Gt: rr.dropGt(step.val)

func keep(rr: Ranges, step: Step): Ranges =
  result = rr
  case step.attr:
    of 'x': result.x = rr.x.keep(step)
    of 'm': result.m = rr.m.keep(step)
    of 'a': result.a = rr.a.keep(step)
    of 's': result.s = rr.s.keep(step)
    else: raise newException(ValueError, $step.attr)

func drop(rr: Ranges, step: Step): Ranges =
  result = rr
  case step.attr:
    of 'x': result.x = rr.x.drop(step)
    of 'm': result.m = rr.m.drop(step)
    of 'a': result.a = rr.a.drop(step)
    of 's': result.s = rr.s.drop(step)
    else: raise newException(ValueError, $step.attr)

func size(r: Range): int =
  r.hi - r.lo + 1

func size(rr: Ranges): int =
  rr.x.size * rr.m.size * rr.a.size * rr.s.size

func impossible(rr: Ranges): bool =
  rr.size <= 0

proc acceptable(sys: System): int =
  var stack: seq[(string, Ranges)]

  stack.add ("in", maxRanges())

  while stack.len > 0:
    var (name, ranges) = stack.pop

    if ranges.impossible:
      continue

    if name == "A":
      result.inc ranges.size
      continue
    if name == "R":
      # result.dec ranges.size
      continue

    let workflow = sys.workflows[name]

    for step in workflow.steps:
      if step.op == None:
        stack.add (step.dest, ranges)
        continue

      stack.add (step.dest, ranges.keep(step))
      ranges = ranges.drop(step)

proc part2(input: string): int =
  let text = readFile(input)
  let system = parseSystem(text)
  system.acceptable

###################

proc timed[T](f: () -> T): T =
  let start = cpuTime()
  result = f()
  echo "Time :", cpuTime() - start

echo timed(proc(): int = part1("input/test.txt"))
echo timed(proc(): int = part1("input/day19.txt"))
echo timed(proc(): int = part2("input/test.txt"))
echo timed(proc(): int = part2("input/day19.txt"))
