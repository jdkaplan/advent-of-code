import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/tables

type Card = tuple
  id: int
  winning: HashSet[int]
  mine: HashSet[int]

proc parseCard(line: string): Card =
  var winning, mine: string
  if not scanf(line, "Card$s$i: $* | $*$.", result.id, winning, mine):
    raise newException(ValueError, line)

  for num in winning.strip.splitWhitespace:
    result.winning.incl num.parseInt

  for num in mine.strip.splitWhitespace:
    result.mine.incl num.parseInt

proc parseCards(text: string): seq[Card] =
  let lines = text.strip.splitLines()

  for line in lines:
    result.add parseCard(line)

func score(card: Card): int =
  let matches = len(card.winning * card.mine)
  if matches > 0:
    2 ^ (matches - 1)
  else:
    0

proc part1(): int =
  let text = readFile("input/day04.txt")
  let cards = parseCards(text)

  for card in cards:
    result.inc card.score

echo part1()
