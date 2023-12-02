import std/strscans
import std/strutils

proc part1(): int =
  let f = open("input/day02.txt")
  defer: f.close()

  let
    reds = 12
    greens = 13
    blues = 14

  var line: string
  while f.readLine(line):
    var id: int
    var rest: string

    block game:
      if not scanf(line, "Game $i: $*$.", id, rest):
        echo "ERROR"
        continue

      for counts in rest.split(";"):
        var r, g, b: int
        for s in counts.split(","):
          let parts = s.strip.split()
          case parts[1]:
            of "red": (if parts[0].parseInt > reds: break game)
            of "green": (if parts[0].parseInt > greens: break game)
            of "blue": (if parts[0].parseInt > blues: break game)
      inc result, id

proc part2(): int =
  let f = open("input/day02.txt")
  defer: f.close()

  var line: string
  while f.readLine(line):
    var id: int
    var rest: string

    if not scanf(line, "Game $i: $*$.", id, rest):
      echo "ERROR"
      continue

    var reds, greens, blues: int

    for counts in rest.split(";"):
      var r, g, b: int
      for s in counts.split(","):
        let parts = s.strip.split()
        case parts[1]:
          of "red": (reds = max(reds, parts[0].parseInt))
          of "green": (greens = max(greens, parts[0].parseInt))
          of "blue": (blues = max(blues, parts[0].parseInt))

    let power = reds * greens * blues
    inc result, power

echo part1()
echo part2()
