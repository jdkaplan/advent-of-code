package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day12.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) int {
	g := NewGraph(lines)
	return g.Paths()
}
func part2(lines []string) int {
	g := NewGraph(lines)
	return g.Paths2()
}

type Graph struct {
	Edges map[string][]string
	Big   map[string]struct{}
	Small map[string]struct{}
}

func NewGraph(lines []string) *Graph {
	g := &Graph{
		Edges: make(map[string][]string),
		Big:   make(map[string]struct{}),
		Small: make(map[string]struct{}),
	}
	for _, l := range lines {
		a, b := aoc.Cut(l, "-")
		g.Edges[a] = append(g.Edges[a], b)
		g.Edges[b] = append(g.Edges[b], a)
		if isBig(a) {
			g.Big[a] = struct{}{}
		} else {
			g.Small[a] = struct{}{}
		}
		if isBig(b) {
			g.Big[b] = struct{}{}
		} else {
			g.Small[b] = struct{}{}
		}
	}
	return g
}

func (g Graph) Neighbors(name string) []string {
	return g.Edges[name]
}

type path []string

func (p path) String() string {
	return strings.Join(p, ",")
}

func (p path) Contains(name string) bool {
	for _, n := range p {
		if n == name {
			return true
		}
	}
	return false
}

func (p path) Tip() string {
	return p[len(p)-1]
}

func (p path) Plus(name string) path {
	// Copy memory to avoid overwriting the last element in the slice.
	p2 := make(path, len(p))
	copy(p2, p)
	return append(p2, name)
}

func (g Graph) Paths() (count int) {
	queue := []path{{"start"}}
	for len(queue) > 0 {
		p := queue[0]
		queue = queue[1:]
		tip := p.Tip()
		for _, n := range g.Neighbors(tip) {
			ext := p.Plus(n)
			if n == "end" {
				count++
				continue
			}
			if !isBig(n) && p.Contains(n) {
				// Don't include small caves twice
				continue
			}
			queue = append(queue, ext)
		}
	}
	return
}

func isBig(name string) bool {
	return strings.ToUpper(name) == name
}

type path2 struct {
	caves   []string
	doubled bool
}

func (p *path2) Plus(name string) (path2, bool) {
	var caves []string
	doubled := p.doubled
	canDupe := isBig(name)
	for _, c := range p.caves {
		caves = append(caves, c)
		if c != name {
			// No dupe.
			continue
		}
		if canDupe {
			continue
		}
		// c == name for a small cave
		if doubled {
			// Already found a doubled cave, can't include this one.
			return path2{}, false
		}
		// Contains two of c now.
		doubled = true
	}
	return path2{
		caves:   append(caves, name),
		doubled: doubled,
	}, true
}

func (p path2) String() string {
	return strings.Join(p.caves, ",")
}

func (p path2) Tip() string {
	return p.caves[len(p.caves)-1]
}

func (g Graph) Paths2() (count int) {
	queue := []path2{
		{
			caves:   []string{"start"},
			doubled: false,
		},
	}
	for len(queue) > 0 {
		p := queue[0]
		queue = queue[1:]
		tip := p.Tip()
		for _, n := range g.Neighbors(tip) {
			if n == "start" {
				// No loops!
				continue
			}
			ext, ok := p.Plus(n)
			if n == "end" {
				count++
				continue
			}
			if !ok {
				continue
			}
			queue = append(queue, ext)
		}
	}
	return
}
