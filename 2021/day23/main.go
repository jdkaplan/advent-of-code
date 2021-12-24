package main

import (
	"container/heap"
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	startText := aoc.Input().ReadFile("day23.txt")
	goalText := aoc.Input().ReadFile("day23-goal.txt")

	w, start := parseInput(startText)
	_, goal := parseInput(goalText)

	fmt.Println(part1(w, start, goal))
}

func parseInput(text string) (Walls, State) {
	w := make(Walls)
	pods := make(map[Object][]RC)
	for r, line := range strings.Split(text, "\n") {
		for c, char := range line {
			if char == '.' || char == ' ' {
				continue
			}
			rc := RC{r, c}
			obj := parseObject(char)
			if obj == Wall {
				w[rc] = true
			}
			pods[obj] = append(pods[obj], rc)
		}
	}
	as := pods[Amber]
	bs := pods[Bronze]
	cs := pods[Copper]
	ds := pods[Desert]
	s := State{
		A: [2]RC{as[0], as[1]},
		B: [2]RC{bs[0], bs[1]},
		C: [2]RC{cs[0], cs[1]},
		D: [2]RC{ds[0], ds[1]},
	}
	return w, s
}

func part1(w Walls, start, goal State) int {
	successors := func(s State) map[State]int {
		return s.Successors(w)
	}
	return search(start, goal, successors)
}

type Object rune

const (
	Empty  Object = '.'
	Wall   Object = '#'
	Amber  Object = 'A'
	Bronze Object = 'B'
	Copper Object = 'C'
	Desert Object = 'D'
)

func parseObject(r rune) Object {
	switch r {
	case '#':
		return Wall
	case '.':
		return Empty
	case 'A':
		return Amber
	case 'B':
		return Bronze
	case 'C':
		return Copper
	case 'D':
		return Desert
	}
	panic(fmt.Sprintf("Unknown object: %s", string(r)))
}

type RC struct{ r, c int }

func (rc RC) Neighbors() []RC {
	r, c := rc.r, rc.c
	return []RC{
		{r - 1, c},
		{r, c - 1},
		{r, c + 1},
		{r + 1, c},
	}
}

type Walls map[RC]bool

func (w Walls) IsDoor(rc RC) bool {
	if rc.r != 1 {
		return false
	}
	switch rc.c {
	case 3, 5, 7, 9:
		return true
	}
	return false
}

func (w Walls) Blocked(rc RC) bool {
	r, c := rc.r, rc.c
	ok := 1 <= r && r <= 3 && 1 <= c && c <= 9
	wall := w[rc]
	return ok && !wall
}

type State struct{ A, B, C, D [2]RC }

func (s State) pods() map[RC]Object {
	return map[RC]Object{
		s.A[0]: Amber,
		s.A[1]: Amber,
		s.B[0]: Bronze,
		s.B[1]: Bronze,
		s.C[0]: Copper,
		s.C[1]: Copper,
		s.D[0]: Desert,
		s.D[1]: Desert,
	}
}
func (s State) Debug(w Walls) string {
	pods := s.pods()
	var sb strings.Builder
	for r := 0; r <= 4; r++ {
		for c := 0; c <= 12; c++ {
			rc := RC{r, c}
			if w[rc] {
				sb.WriteByte('#')
			} else if pod, ok := pods[rc]; ok {
				sb.WriteRune(rune(pod))
			} else {
				sb.WriteByte(' ')
			}
		}
		sb.WriteByte('\n')
	}
	return sb.String()
}

func (s State) Successors(w Walls) map[State]int {
	type Out struct {
		state State
		cost  int
	}
	var outs []Out

	for i, a := range s.A {
		for aa, cost := range podMoves(w, s, a, Amber) {
			n := s
			n.A[i] = aa
			outs = append(outs, Out{n, cost})
		}
	}

	for i, b := range s.B {
		for bb, cost := range podMoves(w, s, b, Bronze) {
			n := s
			n.B[i] = bb
			outs = append(outs, Out{n, cost})
		}
	}

	for i, c := range s.C {
		for cc, cost := range podMoves(w, s, c, Copper) {
			n := s
			n.C[i] = cc
			outs = append(outs, Out{n, cost})
		}
	}

	for i, d := range s.D {
		for dd, cost := range podMoves(w, s, d, Desert) {
			n := s
			n.D[i] = dd
			outs = append(outs, Out{n, cost})
		}
	}

	next := make(map[State]int)
	for _, out := range outs {
		min, ok := next[out.state]
		if !ok || out.cost < min {
			next[out.state] = out.cost
		}
	}
	return next
}

func podMoves(w Walls, s State, start RC, kind Object) (costs map[RC]int) {
	var targetC, cost int
	switch kind {
	case Amber:
		targetC, cost = 3, 1
	case Bronze:
		targetC, cost = 5, 10
	case Copper:
		targetC, cost = 7, 100
	case Desert:
		targetC, cost = 9, 1000
	default:
		panic(":grimace:")
	}
	mode := podMode(w, s, start, kind, targetC)
	return podPath(w, s, start, mode, targetC, cost)
}

type Mode string

const (
	Error Mode = "error"
	Exit  Mode = "exit"
	Wait  Mode = "wait"
	Done  Mode = "done"
)

func podMode(w Walls, s State, rc RC, kind Object, targetC int) Mode {
	pods := s.pods()
	if rc.r == 1 {
		// In the hallway.
		return Wait
	}
	if rc.c == targetC {
		// In correct column.
		inner := RC{3, targetC}
		if rc == inner {
			// No reason to leave!
			return Done
		}
		// Double-parked. Does the other pod want to leave?
		if pods[inner] == kind {
			// Nope, all good!
			return Done
		}
		// Need to let the other pod out.
		return Exit
	}
	return Exit
}

func podPath(w Walls, s State, rc RC, mode Mode, targetC int, cost int) (costs map[RC]int) {
	switch mode {
	case Exit:
		// Any walkable space in the hallway that's not the door.
		costs = make(map[RC]int)
		for _, spot := range walk(w, s, rc) {
			if spot.r == 1 && !w.IsDoor(spot) {
				costs[spot] = cost * manhattan(rc, spot)
			}
		}
		return costs
	case Wait:
		// Only the correct parking spot
		var bestSpot RC
		for _, spot := range walk(w, s, rc) {
			if spot.c != targetC || w.IsDoor(spot) {
				continue
			}
			// Prefer inner (downward, higher-row) spot
			if spot.r > bestSpot.r {
				bestSpot = spot
			}
		}
		if bestSpot == (RC{}) {
			// No available spots
			return nil
		}
		return map[RC]int{
			bestSpot: cost * manhattan(rc, bestSpot),
		}
	case Done:
		// Nothing
		return nil
	default:
		panic("oops")
	}
}

func manhattan(a, b RC) int {
	return abs(a.r-b.r) + abs(a.c-b.c)
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func walk(w Walls, s State, from RC) (spots []RC) {
	queue := []RC{from}
	seen := make(map[RC]bool)
	pods := s.pods()
	var rc RC
	for len(queue) > 0 {
		rc, queue = queue[0], queue[1:]
		if seen[rc] {
			continue
		}
		for _, n := range rc.Neighbors() {
			isWall := w[n]
			_, isFull := pods[n]
			if isWall || isFull {
				continue
			}
			queue = append(queue, n)
		}
		seen[rc] = true
	}
	for spot := range seen {
		spots = append(spots, spot)
	}
	return spots
}

func search(
	start, goal State,
	successors func(State) map[State]int,
) (totalCost int) {
	pq := make(PriorityQueue, 1)
	pq[0] = &Node{
		s:    start,
		cost: 0,
		idx:  0,
	}
	heap.Init(&pq)

	seen := make(map[State]bool)
	for len(pq) > 0 {
		state, cost := pq.Next()
		if state == goal {
			return cost
		}
		if seen[state] {
			continue
		}
		for s, c := range successors(state) {
			pq.Insert(s, cost+c)
		}
		seen[state] = true
	}
	return -1
}

type Node struct {
	s    State
	cost int
	idx  int
}

type PriorityQueue []*Node

func (pq *PriorityQueue) Next() (s State, cost int) {
	n := heap.Pop(pq).(*Node)
	return n.s, n.cost
}

func (pq *PriorityQueue) Insert(s State, cost int) {
	heap.Push(pq, &Node{s: s, cost: cost})
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
