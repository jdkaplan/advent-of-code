import os
from collections import defaultdict
from dataclasses import dataclass


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


def part1(rules, updates):
    constraints = defaultdict(lambda: Constraint(before=set(), after=set()))

    for (x, y) in rules:
        constraints[x].after.add(y)
        constraints[y].before.add(x)

    middles = 0
    for update in updates:
        valid = True
        for (x, y) in zip(update[:-1], update[1:]):
            if x not in constraints or y in constraints[x].after:
                continue
            valid = False
            break

        if valid:
            middles += update[int(len(update)) // 2]

    return middles


print(part1(rules, updates))
