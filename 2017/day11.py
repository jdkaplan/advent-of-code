from enum import Enum
from typing import Tuple, Iterable

import aoc

HexPos = Tuple[int, int, int]


class Direction(Enum):
    N = 0
    NE = 1
    SE = 2
    S = 3
    SW = 4
    NW = 5

    @classmethod
    def parse(cls, s: str):
        match s:
            case 'n': return Direction.N
            case 's': return Direction.S
            case 'ne': return Direction.NE
            case 'nw': return Direction.NW
            case 'se': return Direction.SE
            case 'sw': return Direction.SW
            case _: raise ValueError(f"unknown direction: {s}")


def part1():
    steps = map(Direction.parse, aoc.puzzle_input(11).split(","))
    return distance(walk(steps))


def walk(steps: Iterable[Direction]) -> HexPos:
    pos = (0, 0, 0)
    for step in steps:
        pos = move(pos, step)
    return pos


def distance(pos: HexPos) -> int:
    assert sum(pos) == 0, pos
    return sum(map(abs, pos)) // 2


def move(pos: HexPos, dir: Direction) -> HexPos:
    (q, r, s) = pos
    match dir:
        case Direction.N: return (q, r-1, s+1)
        case Direction.S: return (q, r+1, s-1)

        case Direction.NE: return (q+1, r-1, s)
        case Direction.SW: return (q-1, r+1, s)

        case Direction.NW: return (q-1, r, s+1)
        case Direction.SE: return (q+1, r, s-1)


print(part1())
