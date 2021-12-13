package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day13.txt")
	fmt.Println(part1(text))
	fmt.Println(part2(text))
}

func part1(text string) int {
	g, folds := parse(text)
	g = g.Fold(folds[0])
	return len(g)
}

func part2(text string) string {
	g, folds := parse(text)
	for _, f := range folds {
		g = g.Fold(f)
	}
	return g.String()
}

func parse(text string) (Grid, []Fold) {
	dots, folds := aoc.Cut(text, "\n\n")
	var points []Point
	for _, line := range strings.Split(dots, "\n") {
		x, y := aoc.Cut(line, ",")
		points = append(points, Point{
			x: aoc.MustInt(x),
			y: aoc.MustInt(y),
		})
	}

	var fs []Fold
	for _, line := range strings.Split(folds, "\n") {
		axis, val := aoc.Cut(line[len("fold along "):], "=")
		fs = append(fs, Fold{
			axis: axis,
			val:  aoc.MustInt(val),
		})
	}
	return NewGrid(points), fs
}

type Point struct{ x, y int }

type Grid map[Point]int

type Fold struct {
	axis string
	val  int
}

func NewGrid(points []Point) Grid {
	g := make(Grid)
	for _, p := range points {
		g[p] = 1
	}
	return g
}

func (g Grid) Fold(f Fold) Grid {
	g2 := make(Grid)
	for p, count := range g {
		var p2 Point
		switch axis := f.axis; axis {
		case "x":
			p2 = p.foldX(f.val)
		case "y":
			p2 = p.foldY(f.val)
		default:
			panic(axis)
		}
		g2[p2] += count
	}
	return g2
}

func (p Point) foldX(x int) Point {
	if p.x > x {
		return Point{x - (p.x - x), p.y}
	}
	return p
}

func (p Point) foldY(y int) Point {
	if p.y > y {
		return Point{p.x, y - (p.y - y)}
	}
	return p
}

func (g Grid) String() string {
	xmax, ymax := 0, 0
	for p := range g {
		if p.x > xmax {
			xmax = p.x
		}
		if p.y > ymax {
			ymax = p.y
		}
	}

	var sb strings.Builder
	for y := 0; y <= ymax; y++ {
		for x := 0; x <= xmax; x++ {
			_, ok := g[Point{x, y}]
			if ok {
				sb.WriteString("█")
			} else {
				sb.WriteString(" ")
			}
		}
		sb.WriteString("\n")
	}
	return sb.String()
}
