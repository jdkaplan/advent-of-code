import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables

type Remap = tuple
  dst_start: int
  src_start: int
  length: int

func parseRemap(s: string): Remap =
  let parts = s.splitWhitespace.map(parseInt)
  (parts[0], parts[1], parts[2])

func includes(r: Remap, src: int): bool =
  let range = r.src_start ..< (r.src_start + r.length)
  src in range

func lookup(r: Remap, src: int): int =
  if r.includes(src):
    return r.dst_start + (src - r.src_start)
  src

type Map = object
  src: string
  dst: string
  remaps: seq[Remap]

func parseMap(s: string): Map =
  let lines = s.strip.splitLines
  if not scanf(lines[0], "$+-to-$+ map:$.", result.src, result.dst):
    raise newException(ValueError, lines[0])

  for line in lines[1..^1]:
    result.remaps.add parseRemap(line)

func lookup(m: Map, src: int): int =
  for remap in m.remaps:
    if remap.includes(src):
      return remap.lookup(src)
  src

type Almanac = tuple
  seeds: HashSet[int]
  mapsBySrc: Table[string, Map]
  mapsByDst: Table[string, Map]

func parseAlmanac(s: string): Almanac =
  let sections = s.strip.split("\n\n")

  var seeds: string
  if not scanf(sections[0], "seeds: $*$.", seeds):
    raise newException(ValueError, sections[0])

  for num in seeds.strip.splitWhitespace:
    result.seeds.incl num.parseInt

  for section in sections[1..^1]:
    let map = parseMap(section)
    result.mapsBySrc[map.src] = map
    result.mapsByDst[map.dst] = map

func location(a: Almanac, seed: int): int =
  var map = a.mapsBySrc["seed"]
  var src = seed

  while true:
    src = map.lookup(src)
    if map.dst == "location":
      return src

    map = a.mapsBySrc[map.dst]

proc part1(): int =
  let text = readFile("input/day05.txt")
  let almanac = parseAlmanac(text)

  let locations = collect(newSeq):
    for seed in almanac.seeds:
      almanac.location(seed)

  locations.min

echo part1()
