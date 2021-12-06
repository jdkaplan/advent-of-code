package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day6.txt")
	fmt.Println(part1(text))
	fmt.Println(part2(text))
}

type Fish struct {
	ticks int
}

func NewFish() *Fish {
	return &Fish{8}
}

func (f *Fish) Tick() bool {
	if f.ticks == 0 {
		f.ticks = 6
		return true
	}
	f.ticks--
	return false
}

func part1(text string) int {
	var fish []*Fish
	for _, n := range strings.Split(text, ",") {
		fish = append(fish, &Fish{aoc.MustInt(n)})
	}
	for i := 0; i < 80; i++ {
		for _, f := range fish {
			if f.Tick() {
				fish = append(fish, NewFish())
			}
		}
	}
	return len(fish)
}

func part2(text string) int {
	delays := make(map[int]int)
	for _, n := range strings.Split(text, ",") {
		delays[aoc.MustInt(n)]++
	}
	for i := 0; i < 256; i++ {
		newDelays := make(map[int]int)

		// Reproduce
		newDelays[8] = delays[0]

		// Tick
		for d := 1; d <= 8; d++ {
			newDelays[d-1] = delays[d]
		}
		newDelays[6] += delays[0]

		delays = newDelays
	}

	var total int
	for _, n := range delays {
		total += n
	}
	return total
}
