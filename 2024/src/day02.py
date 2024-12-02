#!/usr/bin/env python3

import os


def relpath(path: str) -> str:
    return os.path.join(os.path.dirname(__file__), path)


reports = []
with open(relpath("../input/day02.txt")) as f:
    for line in f.readlines():
        report = [int(i) for i in line.strip().split()]
        reports.append(report)

Report = list[int]


def sign(x: int) -> int:
    if x > 0:
        return +1
    if x < 0:
        return -1
    return 0


def is_safe(report: Report) -> bool:
    return first_problem(report) is None


def first_problem(report: Report) -> int | None:
    direction = sign(report[1] - report[0])
    for i, (prev, next) in enumerate(zip(report[:-1], report[1:])):
        diff = next - prev
        if direction != sign(diff) or abs(diff) < 1 or abs(diff) > 3:
            return i


def is_safe_tolerant(report: Report) -> bool:
    if is_safe(report):
        return True

    for i in range(len(report)):
        if is_safe(report[:i] + report[i+1:]):
            return True

    return False


n = 0
m = 0
for report in reports:
    if is_safe(report):
        n += 1
    if is_safe_tolerant(report):
        m += 1

print(n)
print(m)
