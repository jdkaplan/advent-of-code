package main

import (
	"fmt"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day22.txt")
	steps := parseInput(lines)
	fmt.Println(part1(steps))
}

func parseInput(lines []string) (steps []Step) {
	for _, line := range lines {
		steps = append(steps, NewStep(line))
	}
	return
}

func part1(steps []Step) int {
	r := make(Reactor)
	r.Initialize(steps)
	return r.CountOn()
}

type Step struct {
	op     string
	x1, x2 int
	y1, y2 int
	z1, z2 int
}

func NewStep(line string) (s Step) {
	aoc.MustScan(
		line,
		"%s x=%d..%d,y=%d..%d,z=%d..%d",
		&s.op, &s.x1, &s.x2, &s.y1, &s.y2, &s.z1, &s.z2,
	)
	return
}

type Cell struct{ x, y, z int }

type Reactor map[Cell]bool

func (r Reactor) Initialize(steps []Step) {
	for _, s := range steps {
		on := s.op == "on"
		for x := max(-50, s.x1); x <= min(50, s.x2); x++ {
			for y := max(-50, s.y1); y <= min(50, s.y2); y++ {
				for z := max(-50, s.z1); z <= min(50, s.z2); z++ {
					r[Cell{x, y, z}] = on
				}
			}
		}
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func (r Reactor) CountOn() (count int) {
	for _, on := range r {
		if on {
			count++
		}
	}
	return
}
