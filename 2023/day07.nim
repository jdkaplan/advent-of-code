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

const five = 7
const four = 6
const full = 5
const three = 4
const twoPair = 3
const pair = 2
const high = 1

func strength(hand: Hand): int =
  let count = newCountTable(hand.cards)

  var counts: CountTable[int]
  for v in values(count):
    counts.inc v

  if counts[5] > 0:
    return five
  if counts[4] > 0:
    return four
  if counts[3] > 0:
    if counts[2] > 0:
      return full
    else:
      return three
  if counts[2] == 2:
    return twoPair
  if counts[2] == 1:
    return pair
  return high

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

func strengthJoker(hand: Hand): int =
  let count = newCountTable(hand.cards)

  let jokers = count[1]

  var regular: CountTable[int]
  for card, count in pairs(count):
    if card == 1:
      continue
    regular.inc count

  if regular[5] > 0:
    return five
  if regular[4] > 0:
    if jokers == 1:
      return five
    return four
  if regular[3] > 0:
    case jokers:
      of 2: return five
      of 1: return four
      else: discard
    if regular[2] > 0:
      return full
    return three
  if regular[2] == 2:
    if jokers == 1:
      return full
    return twoPair
  if regular[2] == 1:
    case jokers:
      of 3: return five
      of 2: return four
      of 1: return three
      else: return pair

  case jokers:
    of 5: return five
    of 4: return five
    of 3: return four
    of 2: return three
    of 1: return pair
    else: return high

func cmpHandJoker(a: Hand, b: Hand): int =
  let strength = cmp(a.strengthJoker, b.strengthJoker)
  if strength != 0:
    return strength

  for (aa, bb) in zip(a.cards, b.cards):
    let card = cmp(aa, bb)
    if card != 0:
      return card

func parseCardJoker(c: char): int =
  case c:
    of 'A': 14
    of 'K': 13
    of 'Q': 12
    of 'J': 1
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

func parseHandJoker(text: string): Hand =
  let parts = text.strip.splitWhitespace
  (parts[0].map(parseCardJoker), parts[1].parseInt)

func parseHandsJoker(text: string): seq[Hand] =
  text.strip.splitLines.map(parseHandJoker)

proc part2(): int =
  let text = readFile("input/day07.txt")
  var hands = parseHandsJoker(text)

  hands.sort(cmpHandJoker)

  for (rank, hand) in enumerate(hands):
    result += (rank + 1) * hand.bid

echo part1()
echo part2()
