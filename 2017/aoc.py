import os


def input_path(day: int) -> str:
    return os.path.join(os.path.dirname(__file__), "input", f"day{day:>02}")


def puzzle_input(day: int) -> str:
    with open(input_path(day)) as f:
        return f.read().strip()
