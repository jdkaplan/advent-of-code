package main

import (
	"fmt"
	"regexp"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day17.txt")
	re := regexp.MustCompile(`^target area: x=(-?\d+)\.\.(-?\d+), y=(-?\d+)..(-?\d+)$`)
	m := re.FindStringSubmatch(text)
	var (
		x1 = aoc.MustInt(m[1])
		x2 = aoc.MustInt(m[2])
		y1 = aoc.MustInt(m[3])
		y2 = aoc.MustInt(m[4])
	)
	r := Region{x1, x2, y1, y2}
	fmt.Println(part1(r))
	fmt.Println(part2(r))
}

type Region struct{ x1, x2, y1, y2 int }

type Position struct{ x, y int }

func (p Position) Move(v Velocity) Position {
	return Position{p.x + v.x, p.y + v.y}
}

func (p Position) InRegion(r Region) bool {
	return r.x1 <= p.x && p.x <= r.x2 && r.y1 <= p.y && p.y <= r.y2
}

func (p Position) Overshot(r Region) bool {
	return p.x > r.x2 || p.y < r.y1
}

type Velocity struct{ x, y int }

func (v Velocity) Drag() Velocity {
	x := v.x
	if x < 0 {
		x++
	} else if x > 0 {
		x--
	}
	return Velocity{x, v.y - 1}
}

func part1(r Region) int {
	vxmin, vxmax := vxrange(r.x1, r.x2)
	vymin, vymax := vyrange(r.y1, r.y2)
	hmax := 0
	for vx := vxmin; vx <= vxmax; vx++ {
		for vy := vymin; vy <= vymax; vy++ {
			hit := simulate(Velocity{vx, vy}, r)
			if !hit {
				continue
			}
			if h := tri(vy); h > hmax {
				hmax = h
			}
		}
	}
	return hmax
}

func part2(r Region) (count int) {
	vxmin, vxmax := vxrange(r.x1, r.x2)
	vymin, vymax := vyrange(r.y1, r.y2)
	for vx := vxmin; vx <= vxmax; vx++ {
		// High parabolas
		for vy := vymin; vy <= vymax; vy++ {
			hit := simulate(Velocity{vx, vy}, r)
			if hit {
				count++
			}
		}
		// Low parabolas
		for vy := vymin - 1; vy >= r.y1; vy-- {
			hit := simulate(Velocity{vx, vy}, r)
			if hit {
				count++
			}
		}
	}
	return
}

func simulate(v Velocity, r Region) bool {
	p := Position{0, 0}
	for !p.InRegion(r) && !p.Overshot(r) {
		p = p.Move(v)
		v = v.Drag()
	}
	return p.InRegion(r)
}

func vxrange(x1, x2 int) (int, int) {
	// Zoom directly to the far edge.
	vxmax := x2
	// Find the first value that crosses the near edge.
	vxmin := 0
	for vx := 0; vx < vxmax; vx++ {
		xterm := tri(vx)
		if xterm >= x1 {
			vxmin = vx
			break
		}
	}
	return vxmin, vxmax
}

func vyrange(y1, y2 int) (int, int) {
	if y1 >= 0 {
		panic("This only works for negative-y regions!")
	}
	// Zoom directly to the close edge.
	vymin := -y2
	// Zoom directly to the far edge.
	vymax := -y1
	return vymin, vymax
}

func tri(x int) int {
	return (x * (x + 1)) / 2
}
