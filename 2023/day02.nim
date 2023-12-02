import std/strscans
import std/strutils

type Turn = object
  r, g, b: int

func parseTurn(text: string): Turn =
  for count in text.split(","):
    let parts = count.strip.split()
    case parts[1]:
      of "red": (result.r = parts[0].parseInt)
      of "green": (result.g = parts[0].parseInt)
      of "blue": (result.b = parts[0].parseInt)


type Game = object
  id: int
  turns: seq[Turn]

func parseGame(line: string): Game =
  var rest: string

  if not scanf(line, "Game $i: $*$.", result.id, rest):
    raise newException(ValueError, line)

  for turn in rest.split(";"):
    result.turns.add(parseTurn(turn))

type Bag = object
  r, g, b: int

proc part1(): int =
  let f = open("input/day02.txt")
  defer: f.close()

  let bag = Bag(r: 12, g: 13, b: 14)

  var line: string
  while f.readLine(line):
    block current:
      let game = parseGame(line)
      for turn in game.turns:
        if turn.r > bag.r: break current
        if turn.g > bag.g: break current
        if turn.b > bag.b: break current
      inc result, game.id

proc part2(): int =
  let f = open("input/day02.txt")
  defer: f.close()

  var line: string
  while f.readLine(line):
    var bag: Bag

    let game = parseGame(line)
    for turn in game.turns:
      bag.r = max(bag.r, turn.r)
      bag.g = max(bag.g, turn.g)
      bag.b = max(bag.b, turn.b)

    let power = bag.r * bag.g * bag.b
    inc result, power

echo part1()
echo part2()
