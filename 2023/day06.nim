import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables

type Race = tuple
  time: int
  distance: int

func parseRaces(text: string): seq[Race] =
  let lines = text.strip.splitLines
  let times = lines[0].splitWhitespace
  let distances = lines[1].splitWhitespace
  assert(times[0] == "Time:")
  assert(distances[0] == "Distance:")

  for (time, distance) in zip(times[1..^1], distances[1..^1]):
    result.add (time.parseInt, distance.parseInt)

func distance_traveled(race: Race, hold_ms: int): int =
  let travel_time = max(0, race.time - hold_ms)
  let speed = hold_ms
  speed * travel_time

func min_win(race: Race): int =
  var hold_ms = 0
  while hold_ms < race.time:
    let dist = race.distance_traveled(hold_ms)
    if dist > race.distance:
      return hold_ms
    inc hold_ms

func max_win(race: Race): int =
  var hold_ms = race.time - 1
  while hold_ms > 0:
    let dist = race.distance_traveled(hold_ms)
    if dist > race.distance:
      return hold_ms
    dec hold_ms

func win_count(race: Race): int =
  let min_ms = race.min_win
  let max_ms = race.max_win
  len(min_ms .. max_ms)

proc dbg[T](v: T): T = (echo(v); v)

proc part1(): int =
  let text = readFile("input/day06.txt")
  let races = parseRaces(text)

  result = 1
  for race in races:
    result *= dbg(race.win_count)

echo part1()
