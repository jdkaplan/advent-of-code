package main

import (
	"fmt"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day22.txt")
	steps := parseInput(lines)
	fmt.Println(part1(steps))
	fmt.Println(part2(steps))
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

func part2(steps []Step) int {
	return reboot(steps)
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

func reboot(steps []Step) int {
	var cells []Cuboid
	for _, s := range steps {
		c := Cuboid{
			x: Interval{s.x1, s.x2},
			y: Interval{s.y1, s.y2},
			z: Interval{s.z1, s.z2},
		}
		cells = cut(cells, c)
		if s.op == "on" {
			cells = append(cells, c)
		}
	}
	return countOn(cells)
}

func countOn(cells []Cuboid) (count int) {
	for _, cell := range cells {
		count += cell.Size()
	}
	return
}

func cut(cells []Cuboid, cutter Cuboid) (stillOn []Cuboid) {
	for _, cell := range cells {
		ix := cell.Intersect(cutter)
		if ix.Empty() {
			stillOn = append(stillOn, cell)
			continue
		}
		mm := cell.Minus(*ix)
		stillOn = append(stillOn, mm...)
	}
	return
}

type Cuboid struct {
	x, y, z Interval
}

func (c Cuboid) String() string {
	return fmt.Sprintf("x: %s, y: %s, z: %s", c.x, c.y, c.z)
}

func (c *Cuboid) Empty() bool {
	return c == nil || c.x.Empty() || c.y.Empty() || c.z.Empty()
}

func (c Cuboid) Size() int {
	return c.x.Size() * c.y.Size() * c.z.Size()
}

func (c Cuboid) Intersect(d Cuboid) (intersection *Cuboid) {
	ix := c.x.Intersect(d.x)
	if ix.Empty() {
		return nil
	}

	iy := c.y.Intersect(d.y)
	if iy.Empty() {
		return nil
	}

	iz := c.z.Intersect(d.z)
	if iz.Empty() {
		return nil
	}

	return &Cuboid{ix, iy, iz}
}

func (c Cuboid) Minus(d Cuboid) []Cuboid {
	x0, x1, x2 := c.x.Split(d.x)
	y0, y1, y2 := c.y.Split(d.y)
	z0, z1, z2 := c.z.Split(d.z)
	return nonEmpty([]Cuboid{
		{x0, y0, z0},
		{x0, y0, z1},
		{x0, y0, z2},
		{x0, y1, z0},
		{x0, y1, z1},
		{x0, y1, z2},
		{x0, y2, z0},
		{x0, y2, z1},
		{x0, y2, z2},
		{x1, y0, z0},
		{x1, y0, z1},
		{x1, y0, z2},
		{x1, y1, z0},
		{x1, y1, z2},
		{x1, y2, z0},
		{x1, y2, z1},
		{x1, y2, z2},
		// {x1, y1, z1}, // Don't include the intersection block
		{x2, y0, z0},
		{x2, y0, z1},
		{x2, y0, z2},
		{x2, y1, z0},
		{x2, y1, z1},
		{x2, y1, z2},
		{x2, y2, z0},
		{x2, y2, z1},
		{x2, y2, z2},
	})
}

func nonEmpty(cs []Cuboid) (nonEmpty []Cuboid) {
	for _, c := range cs {
		if !c.Empty() {
			nonEmpty = append(nonEmpty, c)
		}
	}
	return
}

type Interval [2]int

func (i Interval) String() string {
	return fmt.Sprintf("[%d, %d]", i[0], i[1])
}

func (i Interval) Empty() bool {
	return i.Size() <= 0
}

func (i Interval) Size() int {
	return i[1] - i[0] + 1
}

func (i Interval) Intersect(j Interval) Interval {
	return Interval{
		max(i[0], j[0]),
		min(i[1], j[1]),
	}
}

func (i Interval) Split(j Interval) (prefix, inside, suffix Interval) {
	prefix = Interval{i[0], j[0] - 1}
	inside = Interval{j[0], j[1]}
	suffix = Interval{j[1] + 1, i[1]}
	return
}
