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

type State {.pure.} = enum
  Operational
  Damaged
  Unknown

proc parseState(c: char): State =
  case c:
    of '.': Operational
    of '#': Damaged
    of '?': Unknown
    else: raise newException(ValueError, $c)

proc renderState(s: State): char =
  case s:
    of Operational: '.'
    of Damaged: '#'
    of Unknown: '?'

type Springs = seq[State]

proc parseSprings(line: string): Springs =
  line.strip.map(parseState)

func render(springs: Springs): string =
  springs.mapIt($it.renderState).join

type Runs = seq[int]

type Record = tuple
  springs: Springs
  runs: Runs

func parseRuns(line: string): Runs =
  line.strip.split(',').map(parseInt)

proc parseRecord(line: string): Record =
  let parts = line.strip.splitWhitespace
  assert(parts.len == 2)
  (parts[0].parseSprings, parts[1].parseRuns)

proc parseRecords(text: string): seq[Record] =
  text.strip.splitLines.map(parseRecord)

proc runs(springs: Springs): Runs =
  var state = springs[0]
  var count = 0

  for s in springs:
    if s == Unknown: return @[]

    if s == state:
      inc count
    else:
      if state == Damaged:
        result.add count
      state = s
      count = 1

  if state == Damaged and count > 0:
    result.add count

func solved(springs: Springs, record: Record): bool =
  for (actual, expected) in zip(springs, record.springs):
    if expected != Unknown and actual != expected:
      return false
  springs.runs == record.runs

type Node = tuple
  start: int
  springs: Springs
  runs: Runs

proc successors(n: Node): seq[Node] =
  let (start, springs, runs) = n

  # Nothing to do
  if start >= springs.len: return

  # Everything after here must be operational.
  if runs.len == 0:
    return @[(springs.len, springs.mapIt(if it == Unknown: Operational else: it), @[])]

  # Try putting the first possible run at each index.
  let r = runs[0]

  for i in start ..< springs.len:
    # Inclusive range: [i..j].len == r
    let j = i + r - 1

    # Run would go out of bounds
    if j >= springs.len: continue

    # Any known-good spring prevents this run from being here.
    if springs[i .. j].anyIt(it == Operational): continue

    # Already solved?
    if springs[i .. j].allIt(it == Damaged):
      let after = j+1
      if after == springs.len:
        # Yes, at EOL
        let prefix = springs[0 ..< i].mapIt(if it == Unknown: Operational else: it)
        let new = @[Damaged].cycle(r)
        result.add (i+r+1, prefix & new, runs[1..^1])
      elif springs[after] == Damaged:
        # Nope, impossible
        discard 0
      else:
        # Yes, needs gap
        let prefix = springs[0 ..< i].mapIt(if it == Unknown: Operational else: it)
        let new = @[Damaged].cycle(r) & @[Operational]
        let suffix = springs[after+1 .. ^1]
        result.add (after+1, prefix & new & suffix, runs[1..^1])
      break

    # Can there be a separator after the run?
    let after = j+1
    if after == springs.len:
      # Yes, at EOL => Fill to end
      let prefix = springs[0 ..< i].mapIt(if it == Unknown: Operational else: it)
      let new = @[Damaged].cycle(r)
      result.add (i+r+1, prefix & new, runs[1..^1])
    elif springs[after] == Damaged:
      # No => springs[i] must be operational.
      let prefix = springs[0 ..< i].mapIt(if it == Unknown: Operational else: it)
      let new = @[Operational]
      let suffix = springs[i+1 .. ^1]
      result.add (i+1, prefix & new & suffix, runs)
    else:
      # Yes => springs[after] is operational.
      let prefix = springs[0 ..< i].mapIt(if it == Unknown: Operational else: it)
      let new = @[Damaged].cycle(r) & @[Operational]
      let suffix = springs[after+1 .. ^1]
      result.add (after+1, prefix & new & suffix, runs[1..^1])

proc prompt(msg: string): string =
  stdout.write msg
  stdout.write " "
  stdin.readLine

proc arrangements(r: Record): HashSet[Springs] =
  var queue: seq[Node]

  queue.add (0, r.springs, r.runs)

  while queue.len > 0:
    let current = queue.pop
    let (start, springs, runs) = current
    if solved(springs, r):
      result.incl springs
      continue

    for next in successors(current):
      assert(next.springs.len == r.springs.len)
      queue.add next

proc part1(): int =
  let text = readFile("input/day12.txt")
  let records = parseRecords(text)

  for record in records:
    result.inc record.arrangements.len

echo part1()
