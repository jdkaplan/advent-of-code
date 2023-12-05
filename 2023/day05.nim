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

type Almanac = object
  seeds: seq[int]
  mapsBySrc: Table[string, Map]
  mapsByDst: Table[string, Map]

func parseAlmanac(s: string): Almanac =
  let sections = s.strip.split("\n\n")

  var seeds: string
  if not scanf(sections[0], "seeds: $*$.", seeds):
    raise newException(ValueError, sections[0])

  for num in seeds.strip.splitWhitespace:
    result.seeds.add num.parseInt

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

type Range = tuple
  lo: int
  hi: int

func newRange(start: int, length: int): Range =
  (start, start + length - 1)

func empty(r: Range): bool =
  r.lo > r.hi

func intersect(a: Range, b: Range): Range =
  (max(a.lo, b.lo), min(a.hi, b.hi))

proc lookup(r: Remap, src: Range): Range =
  let delta = r.dst_start - r.src_start
  (src.lo + delta, src.hi + delta)

proc lookup(m: Map, src: Range): seq[Range] =
  var unmapped = @[src]

  for remap in m.remaps:
    var still_unmapped: seq[Range]
    for src in unmapped:
      let rr = newRange(remap.src_start, remap.length)
      if src.intersect(rr).empty:
        still_unmapped.add src
        continue

      let dn = src.lo
      let lo = max(src.lo, rr.lo)
      let hi = min(src.hi, rr.hi)
      let up = src.hi

      let prefix = (dn, lo - 1)
      let inside = (lo, hi)
      let suffix = (hi + 1, up)

      if not prefix.empty:
        still_unmapped.add prefix

      if not suffix.empty:
        still_unmapped.add suffix

      if not inside.empty:
        result.add remap.lookup(inside)

    unmapped = still_unmapped

  for src in unmapped:
    result.add src

proc lookup(m: Map, srcs: seq[Range]): seq[Range] =
  for src in srcs:
    result.add m.lookup(src)

proc lookup(a: Almanac, dst: string, seeds: seq[Range]): seq[Range] =
  var map = a.mapsBySrc["seed"]
  var src = seeds

  while true:
    src = map.lookup(src)
    if map.dst == dst:
      return src

    map = a.mapsBySrc[map.dst]

proc part2(): int =
  let text = readFile("input/day05.txt")
  let almanac = parseAlmanac(text)

  var ranges: seq[Range]

  for i in 0 ..< floorDiv(almanac.seeds.len, 2):
    let start = almanac.seeds[2*i]
    let len = almanac.seeds[2*i + 1]
    ranges.add newRange(start, len)

  let locations = collect(newSeq):
    for locs in almanac.lookup("location", ranges):
      if not locs.empty:
        locs.lo

  locations.min

echo part1()
echo part2()
