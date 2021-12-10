package main

import (
	"fmt"
	"sort"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day10.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) (score int) {
	for _, l := range lines {
		points, _ := parseLine(l)
		score += points
	}
	return
}

func part2(lines []string) int {
	var scores []int
	for _, l := range lines {
		points, stack := parseLine(l)
		if points == 0 {
			scores = append(scores, autocomplete(stack))
		}
	}
	sort.Ints(scores)
	return scores[(len(scores)-1)/2]
}

func parseLine(line string) (score int, stack []rune) {
	for _, c := range line {
		switch c {
		case '(', '[', '{', '<':
			stack = append([]rune{c}, stack...)
		case ')':
			if stack[0] != '(' {
				return 3, stack
			}
			stack = stack[1:]
		case ']':
			if stack[0] != '[' {
				return 57, stack
			}
			stack = stack[1:]
		case '}':
			if stack[0] != '{' {
				return 1197, stack
			}
			stack = stack[1:]
		case '>':
			if stack[0] != '<' {
				return 25137, stack
			}
			stack = stack[1:]
		}
	}
	return 0, stack
}

func autocomplete(stack []rune) (score int) {
	for _, c := range stack {
		score *= 5
		switch c {
		case '(':
			score += 1
		case '[':
			score += 2
		case '{':
			score += 3
		case '<':
			score += 4
		}
	}
	return
}
