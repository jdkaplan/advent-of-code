import std/algorithm
import std/enumerate
import std/math
import std/sequtils
import std/sets
import std/strscans
import std/strutils
import std/sugar
import std/tables

type Hand = tuple
  cards: seq[int]
  bid: int

func parseCard(c: char): int =
  case c:
    of 'A': 14
    of 'K': 13
    of 'Q': 12
    of 'J': 11
    of 'T': 10
    of '9': 9
    of '8': 8
    of '7': 7
    of '6': 6
    of '5': 5
    of '4': 4
    of '3': 3
    of '2': 2
    else: 0

func parseHand(text: string): Hand =
  let parts = text.strip.splitWhitespace
  (parts[0].map(parseCard), parts[1].parseInt)

func parseHands(text: string): seq[Hand] =
  text.strip.splitLines.map(parseHand)

func strength(hand: Hand): int =
  let count = newCountTable(hand.cards)

  var counts: CountTable[int]
  for v in values(count):
    counts.inc v

  if counts[5] > 0:
    return 7
  if counts[4] > 0:
    return 6
  if counts[3] > 0:
    if counts[2] > 0:
      return 5
    else:
      return 4
  if counts[2] == 2:
    return 3
  if counts[2] == 1:
    return 2
  return 1

func cmpHand(a: Hand, b: Hand): int =
  let strength = cmp(a.strength, b.strength)
  if strength != 0:
    return strength

  for (aa, bb) in zip(a.cards, b.cards):
    let card = cmp(aa, bb)
    if card != 0:
      return card

proc dbg[T](v: T): T = (echo(v); v)

proc part1(): int =
  let text = readFile("input/day07.txt")
  var hands = parseHands(text)

  hands.sort(cmpHand)

  for (rank, hand) in enumerate(hands):
    result += (rank + 1) * hand.bid

echo part1()
