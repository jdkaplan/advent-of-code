import os

from collections import defaultdict
from dataclasses import dataclass
from itertools import product
from typing import Self, Iterator
from pprint import pprint


@dataclass
class Point:
    x: int
    y: int
    z: int

    @classmethod
    def parse(cls, text: str) -> Self:
        x, y, z = [int(n) for n in text.split(',')]
        return cls(x, y, z)

    def __str__(self) -> str:
        return f"({self.x}, {self.y}, {self.z})"

    def __repr__(self) -> str:
        return f"Point({self.x}, {self.y}, {self.z})"

    def __hash__(self) -> int:
        return hash((self.x, self.y, self.z))

    def __lt__(self: Self, other: Self) -> bool:
        return (self.z, self.x, self.y) < (other.z, other.x, other.y)


@dataclass
class Brick:
    id: int
    a: Point
    b: Point

    @classmethod
    def parse(cls, id: int, text: str) -> Self:
        a, b = text.split('~')
        a = Point.parse(a)
        b = Point.parse(b)
        assert a.x <= b.x and a.y <= b.y and a.z <= b.z
        return cls(id, a, b)

    def __str__(self) -> str:
        return f"{self.id} = {self.a} ~ {self.b}"

    def __repr__(self) -> str:
        return f"Brick({self.id}, {self.a}, {self.b})"

    def points(self) -> Iterator[Point]:
        for x in range(self.a.x, self.b.x+1):
            for y in range(self.a.y, self.b.y+1):
                for z in range(self.a.z, self.b.z+1):
                    yield Point(x, y, z)


@dataclass
class Snapshot:
    bricks: list[Brick]

    @classmethod
    def parse(cls, text: str) -> Self:
        bricks = [
            Brick.parse(i + 1, line)
            for i, line in enumerate(text.splitlines())
        ]
        return cls(bricks)


def solve(snap: Snapshot) -> tuple[int, int]:
    supports: dict[int, set[int]] = defaultdict(lambda: set())
    tower: dict[Point, int] = {}
    bricks: dict[int, Brick] = {}

    lo = Point(0, 0, 0)
    hi = Point(0, 0, 0)

    for brick in snap.bricks:
        bricks[brick.id] = brick
        for p in brick.points():
            tower[p] = brick.id

            lo = Point(
                min(lo.x, p.x),
                min(lo.y, p.y),
                min(lo.z, p.z),
            )
            hi = Point(
                max(hi.x, p.x),
                max(hi.y, p.y),
                max(hi.z, p.z),
            )

    ids = list(bricks.keys())

    changed = True
    while changed:
        changed = False
        for id in ids:
            brick = bricks[id]

            new_z = None
            for z in range(brick.a.z-1, 0, -1):
                supported = False
                surface = product(
                    range(brick.a.x, brick.b.x + 1),
                    range(brick.a.y, brick.b.y + 1),
                )
                for (x, y) in surface:
                    if tower.get(Point(x, y, z)):
                        supported = True
                        break
                if supported:
                    new_z = z + 1
                    break
            else:
                new_z = 1

            dz = brick.a.z - new_z
            assert dz >= 0

            if dz == 0:
                continue

            for p in brick.points():
                del tower[p]

            brick.a.z -= dz
            brick.b.z -= dz

            for p in brick.points():
                tower[p] = brick.id
            changed = True

    for brick in snap.bricks:
        for z in range(brick.a.z-1, 0, -1):
            surface = product(
                range(brick.a.x, brick.b.x + 1),
                range(brick.a.y, brick.b.y + 1),
            )
            for (x, y) in surface:
                lower = tower.get(Point(x, y, z))
                if not lower:
                    continue
                supports[brick.id].add(lower)
            if supports[brick.id]:
                break

    solos: set[int] = set()
    for v in supports.values():
        if len(v) == 1:
            solos.add(next(iter(v)))
    part1 = len(snap.bricks) - len(solos)

    part2 = 0
    for root in solos:
        falling = {root}

        changed = True
        while changed:
            changed = False
            for id, support in supports.items():
                if id in falling:
                    continue
                if support <= falling:
                    falling.add(id)
                    changed = True

        part2 += len(falling) - 1

    return (part1, part2)


def relpath(path: str) -> str:
    return os.path.join(os.path.dirname(__file__), path)


input_path = "./input/day22.txt"
with open(relpath(input_path)) as f:
    snap = Snapshot.parse(f.read())


part1, part2 = solve(snap)
print(part1)
print(part2)
