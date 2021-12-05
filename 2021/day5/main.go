package main

import (
	"fmt"
	"math"

	"github.com/jdkaplan/advent-of-code/aoc"
)

type Point struct {
	x, y int
}

func (p Point) Plus(dx, dy int) Point {
	return Point{x: p.x + dx, y: p.y + dy}
}

type Line struct {
	p1, p2 Point
}

func (l Line) Slope() float64 {
	dx := float64(l.p2.x - l.p1.x)
	dy := float64(l.p2.y - l.p1.y)
	return dy / dx
}

func (l Line) Delta() (dx, dy int) {
	switch s := l.Slope(); s {
	case 0:
		if l.p1.x < l.p2.x {
			return 1, 0
		}
		return -1, 0
	case math.Inf(+1):
		if l.p1.y < l.p2.y {
			return 0, 1
		}
		return 0, -1
	case +1:
		if l.p1.x < l.p2.x {
			return 1, 1
		}
		return -1, -1
	case -1:
		if l.p1.x < l.p2.x {
			return 1, -1
		}
		return -1, 1
	default:
		panic(s)
	}
}

func parse(flines []string) (lines []Line) {
	for _, l := range flines {
		s, e := aoc.Cut(l, " -> ")
		x1, y1 := aoc.Cut(s, ",")
		x2, y2 := aoc.Cut(e, ",")
		p1 := Point{
			x: aoc.MustInt(x1),
			y: aoc.MustInt(y1),
		}
		p2 := Point{
			x: aoc.MustInt(x2),
			y: aoc.MustInt(y2),
		}
		if p1.x > p2.x || p1.y > p2.y {
			// This point is backwards!
			p1, p2 = p2, p1
		}
		lines = append(lines, Line{p1: p1, p2: p2})
	}
	return
}
func part1(flines []string) int {
	grid := make(map[Point]int)
	for _, l := range parse(flines) {
		switch l.Slope() {
		case 0:
			y := l.p1.y
			for x := l.p1.x; x <= l.p2.x; x++ {
				grid[Point{x: x, y: y}]++
			}
		case math.Inf(+1), math.Inf(-1):
			x := l.p1.x
			for y := l.p1.y; y <= l.p2.y; y++ {
				grid[Point{x: x, y: y}]++
			}
		}
	}
	var count int
	for _, c := range grid {
		if c > 1 {
			count++
		}
	}
	return count
}

func part2(flines []string) int {
	grid := make(map[Point]int)
	for _, l := range parse(flines) {
		dx, dy := l.Delta()
		for p := l.p1; p != l.p2; p = p.Plus(dx, dy) {
			grid[p]++
		}
		grid[l.p2]++
	}
	var count int
	for _, c := range grid {
		if c > 1 {
			count++
		}
	}
	return count
}

func main() {
	lines := aoc.Input().ReadLines("day5.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}
