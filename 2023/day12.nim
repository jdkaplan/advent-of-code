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

proc successors(r: Record): seq[Record] =
  let (springs, runs) = r

  # Nothing to do
  if springs.len == 0: return

  if runs.len == 0:
    # Everything after here must be operational.
    if springs.allIt(it != Damaged):
      return @[(@[], @[])]
    return @[]

  # Try placing the first available run.
  let r = runs[0]

  for i in 0 ..< springs.len:
    # Inclusive range: [i..j].len == r
    let j = i + r - 1

    # Run would go out of bounds.
    if j >= springs.len: continue

    # Any known-good spring prevents this run from being here.
    if springs[i .. j].anyIt(it == Operational): continue

    # A damaged spring before prevents this run from being here.
    if springs[0..<i].anyIt(it == Damaged): continue

    # A damaged spring after prevents this run from being here.
    if j < springs.high and springs[j+1] == Damaged: continue

    # Already solved?
    if springs[i .. j].allIt(it == Damaged):
      let after = j+1
      if after == springs.len:
        # Yes, at EOL
        result.add (@[], runs[1..^1])
      else:
        # Yes, needs gap
        assert springs[after] != Damaged
        let suffix = springs[after+1 .. ^1]
        result.add (suffix, runs[1..^1])
      break

    # Can there be a separator after the run?
    let after = j+1
    if after == springs.len:
      # Yes, at EOL => Fill to end
      result.add (@[], runs[1..^1])
    else:
      # Yes => springs[after] is operational.
      assert springs[after] != Damaged
      let suffix = springs[after+1 .. ^1]
      result.add (suffix, runs[1..^1])

proc prompt(msg: string): string =
  stdout.write msg
  stdout.write " "
  stdin.readLine

proc solved(r: Record): bool =
  r.runs.len == 0 and r.springs.allIt(it != Unknown)

proc impossible(r: Record): bool =
  (
    r.runs.len == 0 and r.springs.anyIt(it == Damaged)
  ) or (
    r.runs.len > 0 and r.springs.allIt(it == Operational)
  )

proc arrangements(r: Record, memo: var Table[Record, int]): int =
  if r in memo:
    return memo[r]

  if r.impossible:
    return 0

  if r.solved:
    return 1

  for suffix in successors(r):
    result.inc arrangements(suffix, memo)

  memo[r] = result

proc arrangements(r: Record): int =
  var memo: Table[Record, int]
  arrangements(r, memo)

proc part1(input: string): int =
  let text = readFile(input)
  let records = parseRecords(text)

  for (i, record) in enumerate(records):
    result.inc record.arrangements

func unfold(record: Record): Record =
  var springs = record.springs
  for _ in 1..4:
    springs = springs & @[Unknown]
    springs = springs & record.springs
  assert springs.len == 5 * record.springs.len + 4
  (springs, record.runs.cycle(5))

proc part2(input: string): int =
  let text = readFile(input)
  let records = parseRecords(text).map(unfold)

  for record in records:
    result.inc record.arrangements

echo part1("input/test.txt")
echo part1("input/day12.txt")
echo part2("input/test.txt")
echo part2("input/day12.txt")
