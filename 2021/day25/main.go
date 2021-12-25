package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day25.txt")
	fmt.Println(part1(lines))
}

func part1(lines []string) int {
	f := NewFloor(lines)
	moved := true
	i := 0
	for moved {
		f, moved = f.Tick()
		i++
	}
	return i
}

type RC struct{ r, c int }

type Floor struct {
	east, south map[RC]bool
	rows, cols  int
}

func NewFloor(lines []string) Floor {
	f := Floor{
		east:  make(map[RC]bool),
		south: make(map[RC]bool),
		rows:  len(lines),
		cols:  len(lines[0]),
	}
	for r, row := range lines {
		for c, char := range row {
			rc := RC{r, c}
			switch char {
			case 'v':
				f.south[rc] = true
			case '>':
				f.east[rc] = true
			}
		}
	}
	return f
}

func (f Floor) Occupied(rc RC) bool {
	return f.east[rc] || f.south[rc]
}

func (f Floor) EastOf(rc RC) RC {
	c := (rc.c + 1) % f.cols
	return RC{rc.r, c}
}

func (f Floor) SouthOf(rc RC) RC {
	r := (rc.r + 1) % f.rows
	return RC{r, rc.c}
}

func (f Floor) Tick() (Floor, bool) {
	next, eastward := f.TickEast()
	next, southward := next.TickSouth()
	return next, eastward || southward
}

func (f Floor) TickEast() (Floor, bool) {
	next := f
	next.east = make(map[RC]bool)
	moved := false
	for rc := range f.east {
		t := f.EastOf(rc)
		if f.Occupied(t) {
			next.east[rc] = true
		} else {
			next.east[t] = true
			moved = true
		}
	}
	return next, moved
}

func (f Floor) TickSouth() (Floor, bool) {
	next := f
	next.south = make(map[RC]bool)
	moved := false
	for rc := range f.south {
		t := f.SouthOf(rc)
		if f.Occupied(t) {
			next.south[rc] = true
		} else {
			next.south[t] = true
			moved = true
		}
	}
	return next, moved
}

func (f Floor) String() string {
	var sb strings.Builder
	for r := 0; r < f.rows; r++ {
		for c := 0; c < f.cols; c++ {
			rc := RC{r, c}
			switch {
			case f.east[rc]:
				sb.WriteByte('>')
			case f.south[rc]:
				sb.WriteByte('v')
			default:
				sb.WriteByte('.')
			}
		}
		sb.WriteString("\n")
	}
	return sb.String()
}
