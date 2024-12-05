import os
from collections import defaultdict
from dataclasses import dataclass
from functools import cmp_to_key


def relpath(path: str) -> str:
    return os.path.join(os.path.dirname(__file__), path)


with open(relpath("../input/day05.txt")) as f:
    text = f.read()
    sections = text.split("\n\n")

    rules = [
        tuple(map(int, line.split("|")))
        for line in sections[0].splitlines()
    ]

    updates = [
        tuple(map(int, line.split(",")))
        for line in sections[1].splitlines()
    ]


@dataclass
class Constraint:
    before: set[int]
    after: set[int]


constraints = defaultdict(lambda: Constraint(before=set(), after=set()))

for (x, y) in rules:
    constraints[x].after.add(y)
    constraints[y].before.add(x)


def is_valid(update):
    for (x, y) in zip(update[:-1], update[1:]):
        if x not in constraints or y in constraints[x].after:
            continue
        return False
    return True


def part1():
    return sum(
        update[int(len(update)) // 2]
        for update in updates
        if is_valid(update)
    )


def part2():
    def compare(x, y):
        if y in constraints[x].after:
            return +1
        if y in constraints[x].before:
            return -1
        return 0

    return sum(
        sorted(update, key=cmp_to_key(compare))[int(len(update)) // 2]
        for update in updates
        if not is_valid(update)
    )


print(part1())
print(part2())
