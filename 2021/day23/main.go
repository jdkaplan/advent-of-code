package main

import (
	"container/heap"
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	startText := aoc.Input().ReadFile("day23-part2.txt")
	w, start := parseInput(startText)
	fmt.Println(part1(w, start))
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
	if len(as) != podCount {
		panic(as)
	}
	if len(bs) != podCount {
		panic(bs)
	}
	if len(cs) != podCount {
		panic(cs)
	}
	if len(ds) != podCount {
		panic(ds)
	}
	s := State{
		A: [podCount]RC{as[0], as[1], as[2], as[3]},
		B: [podCount]RC{bs[0], bs[1], bs[2], bs[3]},
		C: [podCount]RC{cs[0], cs[1], cs[2], cs[3]},
		D: [podCount]RC{ds[0], ds[1], ds[2], ds[3]},
	}
	return w, s
}

func part1(w Walls, start State) int {
	successors := func(s State) map[State]int {
		fmt.Println(s.Debug(w))
		return s.Successors(w)
	}
	return search(start, State.Goal, successors, State.Wrong)
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

const podCount = 4
const rHallway = 1
const rMax = rHallway + podCount

type Walls map[RC]bool

func (w Walls) IsDoor(rc RC) bool {
	if rc.r != rHallway {
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
	ok := rHallway <= r && r <= rMax && 1 <= c && c <= 9
	wall := w[rc]
	return ok && !wall
}

type State struct{ A, B, C, D [podCount]RC }

func (s State) pods() map[RC]Object {
	p := make(map[RC]Object)
	for _, a := range s.A {
		p[a] = Amber
	}
	for _, b := range s.B {
		p[b] = Bronze
	}
	for _, c := range s.C {
		p[c] = Copper
	}
	for _, d := range s.D {
		p[d] = Desert
	}
	return p
}

func (s State) Debug(w Walls) string {
	pods := s.pods()
	var sb strings.Builder
	for r := 0; r <= rMax+1; r++ {
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

func (s State) Goal() bool {
	for _, a := range s.A {
		if a.c != 3 {
			return false
		}
	}
	for _, b := range s.B {
		if b.c != 5 {
			return false
		}
	}
	for _, c := range s.C {
		if c.c != 7 {
			return false
		}
	}
	for _, d := range s.D {
		if d.c != 9 {
			return false
		}
	}
	return true
}

func (s State) Wrong() (cost int) {
	for _, a := range s.A {
		if a.c != 3 {
			cost += 2
		}
	}
	for _, b := range s.B {
		if b.c != 5 {
			cost += 20
		}
	}
	for _, c := range s.C {
		if c.c != 7 {
			cost += 200
		}
	}
	for _, d := range s.D {
		if d.c != 9 {
			cost += 2000
		}
	}
	return
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
	Exit Mode = "exit"
	Wait Mode = "wait"
	Park Mode = "park"
	Done Mode = "done"
)

func podMode(w Walls, s State, rc RC, kind Object, targetC int) Mode {
	pods := s.pods()
	if rc.r == rHallway {
		// In the hallway. Would another pod need to leave?
		for r := rc.r + 1; r <= rMax; r++ {
			inner := RC{r, targetC}
			if k, ok := pods[inner]; ok && k != kind {
				// Need to let the other pod out.
				return Wait
			}
		}
		// Nope, get moving!
		return Park
	}
	if rc.c == targetC {
		// In correct column. Does another pod want to leave?
		for r := rc.r + 1; r <= rMax; r++ {
			inner := RC{r, targetC}
			if k, ok := pods[inner]; ok && k != kind {
				// Need to let the other pod out.
				return Exit
			}
		}
		// No reason to leave!
		return Done
	}
	return Exit
}

func podPath(w Walls, s State, rc RC, mode Mode, targetC int, cost int) (costs map[RC]int) {
	switch mode {
	case Exit:
		// Any walkable space in the hallway that's not the door.
		costs = make(map[RC]int)
		for _, spot := range walk(w, s, rc) {
			if spot.r == rHallway && !w.IsDoor(spot) {
				costs[spot] = cost * manhattan(rc, spot)
			}
		}
		return costs
	case Wait:
		// Do nothing
		return nil
	case Park:
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
	start State,
	isGoal func(State) bool,
	successors func(State) map[State]int,
	heuristic func(State) int,
) (totalCost int) {
	if heuristic == nil {
		heuristic = func(State) int { return 0 }
	}

	pq := make(PriorityQueue, 1)
	pq[0] = &Node{
		s:    start,
		cost: 0,
		heur: 0,
		idx:  0,
	}
	heap.Init(&pq)

	seen := make(map[State]bool)
	for len(pq) > 0 {
		state, cost := pq.Next()
		if isGoal(state) {
			return cost
		}
		if seen[state] {
			continue
		}
		for s, c := range successors(state) {
			pq.Insert(s, cost+c, heuristic(state))
		}
		seen[state] = true
	}
	return -1
}

type Node struct {
	s    State
	cost int
	heur int
	idx  int
}

type PriorityQueue []*Node

func (pq *PriorityQueue) Next() (s State, cost int) {
	n := heap.Pop(pq).(*Node)
	return n.s, n.cost
}

func (pq *PriorityQueue) Insert(s State, cost int, heur int) {
	heap.Push(pq, &Node{s: s, cost: cost, heur: heur})
}

func (pq PriorityQueue) Len() int {
	return len(pq)
}

func (pq PriorityQueue) Less(i, j int) bool {
	ii := pq[i].cost + pq[i].heur
	jj := pq[j].cost + pq[j].heur
	return ii < jj
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
