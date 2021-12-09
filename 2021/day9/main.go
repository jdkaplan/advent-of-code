package main

import (
	"fmt"
	"sort"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day9.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) (risk int) {
	g := NewGrid(lines)
	for r := 0; r < g.Rows; r++ {
		for c := 0; c < g.Cols; c++ {
			risk += g.Risk(r, c)
		}
	}
	return risk
}

func part2(lines []string) int {
	g := NewGrid(lines)
	var starts []RC
	for r := 0; r < g.Rows; r++ {
		for c := 0; c < g.Cols; c++ {
			if g.Risk(r, c) != 0 {
				starts = append(starts, RC{r, c})
			}
		}
	}

	var sizes []int
	for _, rc := range starts {
		sizes = append(sizes, g.Flood(rc))
	}
	sort.Sort(sort.Reverse(sort.IntSlice(sizes)))
	return sizes[0] * sizes[1] * sizes[2]
}

type RC struct{ r, c int }

type Grid struct {
	Rows int
	Cols int

	m map[RC]int
}

func NewGrid(lines []string) Grid {
	g := Grid{
		m:    make(map[RC]int),
		Rows: len(lines),
		Cols: len(lines[0]),
	}
	for r, row := range lines {
		for c, col := range row {
			g.m[RC{r, c}] = int(col - '0')
		}
	}
	return g
}

func (g Grid) Risk(r, c int) int {
	rc := RC{r, c}
	v, ok := g.m[rc]
	if !ok {
		return 0
	}
	for _, n := range g.Neighbors(rc) {
		u, ok := g.m[n]
		if ok && u <= v {
			return 0
		}
	}
	return v + 1
}

func (g Grid) Neighbors(rc RC) []RC {
	r, c := rc.r, rc.c
	return []RC{
		{r - 1, c},
		{r, c + 1},
		{r + 1, c},
		{r, c - 1},
	}
}

func (g Grid) Flood(rc RC) (size int) {
	queue := []RC{rc}
	seen := make(map[RC]bool)
	for len(queue) > 0 {
		rc, queue = queue[0], queue[1:]
		if seen[rc] {
			continue
		}
		for _, n := range g.Neighbors(rc) {
			if v, ok := g.m[n]; ok && v < 9 {
				queue = append(queue, n)
			}
		}
		seen[rc] = true
		size++
	}
	return size
}
