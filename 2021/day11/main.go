package main

import (
	"fmt"
	"strings"

	"github.com/fatih/color"
	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day11.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) (flashes int) {
	g := NewGrid(lines)
	for i := 0; i < 100; i++ {
		count := g.Tick()
		flashes += count
	}
	return
}

func part2(lines []string) int {
	g := NewGrid(lines)
	all := g.Rows * g.Cols
	for i := 0; true; i++ {
		if g.Tick() == all {
			return i + 1
		}
	}
	return 0
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

var red = color.New(color.FgRed)

func (g Grid) String() string {
	var sb strings.Builder
	for r := 0; r < g.Rows; r++ {
		for c := 0; c < g.Cols; c++ {
			if e := g.m[RC{r, c}]; e == 0 {
				red.Fprintf(&sb, "%d", e)
			} else {
				fmt.Fprintf(&sb, "%d", e)
			}
		}
		sb.WriteString("\n")
	}
	return sb.String()
}

func (g Grid) Equal(o Grid) bool {
	for r := 0; r < g.Rows; r++ {
		for c := 0; c < g.Cols; c++ {
			rc := RC{r, c}
			if g.m[rc] != o.m[rc] {
				return false
			}
		}
	}
	return true
}

func (g *Grid) Tick() (flashes int) {
	var frontier []RC
	flashed := make(map[RC]bool)
	for r := 0; r < g.Rows; r++ {
		for c := 0; c < g.Cols; c++ {
			rc := RC{r, c}
			g.m[rc]++
			if g.m[rc] > 9 {
				frontier = append(frontier, rc)
			}
		}
	}

	for len(frontier) > 0 {
		rc := frontier[0]
		frontier = frontier[1:]
		if flashed[rc] {
			continue
		}
		for _, n := range g.Neighbors(rc) {
			g.m[n]++
			if g.m[n] > 9 {
				frontier = append(frontier, n)
			}
		}
		flashed[rc] = true
	}
	for rc := range flashed {
		g.m[rc] = 0
	}
	return len(flashed)
}

func (g Grid) Neighbors(rc RC) (ns []RC) {
	r, c := rc.r, rc.c
	for _, n := range []RC{
		{r - 1, c - 1}, {r - 1, c}, {r - 1, c + 1},
		{r, c - 1}, {r, c + 1},
		{r + 1, c - 1}, {r + 1, c}, {r + 1, c + 1},
	} {
		if 0 <= n.r && n.r < g.Rows && 0 <= n.c && n.c < g.Cols {
			ns = append(ns, n)
		}
	}
	return
}
