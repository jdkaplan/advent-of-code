package main

import (
	"container/heap"
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day15.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) int {
	g := NewGrid(lines)
	start := RC{0, 0}
	goal := RC{g.Rows - 1, g.Cols - 1}
	return lowrisk(start, goal, g.Neighbors, g.Risk)
}

func part2(lines []string) int {
	g := NewGrid(lines)
	start := RC{0, 0}
	goal := RC{5*g.Rows - 1, 5*g.Cols - 1}
	return lowrisk(start, goal, g.Neighbors2, g.Risk2)
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

func (g Grid) Neighbors(rc RC) (ns []RC) {
	r, c := rc.r, rc.c
	for _, n := range []RC{
		{r - 1, c},
		{r, c - 1},
		{r, c + 1},
		{r + 1, c},
	} {
		if 0 <= n.r && n.r < g.Rows && 0 <= n.c && n.c < g.Cols {
			ns = append(ns, n)
		}
	}
	return
}

func (g Grid) Risk(rc RC) int {
	return g.m[rc]
}

func (g Grid) Neighbors2(rc RC) (ns []RC) {
	r, c := rc.r, rc.c
	for _, n := range []RC{
		{r - 1, c},
		{r, c - 1},
		{r, c + 1},
		{r + 1, c},
	} {
		if 0 <= n.r && n.r < 5*g.Rows && 0 <= n.c && n.c < 5*g.Cols {
			ns = append(ns, n)
		}
	}
	return
}

func (g Grid) Risk2(rc RC) int {
	rr := rc.r % g.Rows
	cc := rc.c % g.Cols
	xr := rc.r / g.Rows
	xc := rc.c / g.Cols
	return (((g.m[RC{rr, cc}] + xr + xc) - 1) % 9) + 1
}

func (g Grid) String() string {
	var sb strings.Builder
	for r := 0; r < 5*g.Rows; r++ {
		for c := 0; c < 5*g.Cols; c++ {
			fmt.Fprintf(&sb, "%d", g.Risk2(RC{r, c}))
		}
		sb.WriteString("\n")
	}
	return sb.String()
}

func lowrisk(
	start, goal RC,
	neighborsFn func(RC) []RC,
	costFn func(RC) int,
) (risk int) {
	pq := make(PriorityQueue, 1)
	pq[0] = &Node{
		rc:   start,
		cost: 0,
		idx:  0,
	}
	heap.Init(&pq)

	seen := make(map[RC]bool)
	for len(pq) > 0 {
		rc, cost := pq.Next()
		if rc == goal {
			return cost
		}
		if seen[rc] {
			continue
		}
		for _, n := range neighborsFn(rc) {
			pq.Insert(n, cost+costFn(n))
		}
		seen[rc] = true
	}
	return -1
}

type Node struct {
	rc   RC
	cost int
	idx  int
}

type PriorityQueue []*Node

func (pq *PriorityQueue) Next() (rc RC, cost int) {
	n := heap.Pop(pq).(*Node)
	return n.rc, n.cost
}

func (pq *PriorityQueue) Insert(rc RC, cost int) {
	heap.Push(pq, &Node{rc: rc, cost: cost})
}

func (pq PriorityQueue) Len() int {
	return len(pq)
}

func (pq PriorityQueue) Less(i, j int) bool {
	return pq[i].cost < pq[j].cost
}

func (p PriorityQueue) Swap(i, j int) {
	p[i], p[j] = p[j], p[i]
	p[i].idx = i
	p[j].idx = j
}

func (pq *PriorityQueue) Push(x interface{}) {
	n := len(*pq)
	node := x.(*Node)
	node.idx = n
	*pq = append(*pq, node)
}

func (pq *PriorityQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	node := old[n-1]
	old[n-1] = nil
	node.idx = -1
	*pq = old[0 : n-1]
	return node
}
