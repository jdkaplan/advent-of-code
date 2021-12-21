package main

import (
	"fmt"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day21.txt")
	p1, p2 := parseInput(lines)
	fmt.Println(part1(p1, p2))
	fmt.Println(part2(p1, p2))
}

func parseInput(lines []string) (p1, p2 int) {
	aoc.MustScan(lines[0], "Player 1 starting position: %d", &p1)
	aoc.MustScan(lines[1], "Player 2 starting position: %d", &p2)
	return
}

func part1(p1, p2 int) int {
	g := NewGame(p1, p2, &DD100{})
	for i := 1; true; i++ {
		hash := g.Turn(i)
		if hash != 0 {
			return hash
		}
	}
	return 0
}

type Game struct {
	p1, p2 int
	s1, s2 int
	die    Roller
}

func NewGame(p1, p2 int, die Roller) *Game {
	return &Game{p1, p2, 0, 0, die}
}

func (g *Game) String() string {
	return fmt.Sprintf("P1: %2d, S1: %5d | P1: %2d, S1: %5d", g.p1, g.s1, g.p2, g.s2)
}

func (g *Game) Turn(turns int) (hash int) {
	if g.P1() {
		return g.s2 * (6*turns - 3)
	}
	if g.P2() {
		return g.s1 * (6 * turns)
	}
	return 0
}

func (g *Game) P1() (won bool) {
	roll := g.die.Roll() + g.die.Roll() + g.die.Roll()
	g.p1 = move(g.p1, roll)
	g.s1 += score(g.p1)
	return g.s1 >= 1000
}

func (g *Game) P2() (won bool) {
	roll := g.die.Roll() + g.die.Roll() + g.die.Roll()
	g.p2 = move(g.p2, roll)
	g.s2 += score(g.p2)
	return g.s2 >= 1000
}

func move(pos, roll int) int {
	// 0-index for math, 1-index for position.
	return ((pos-1)+roll)%10 + 1
}

func score(pos int) int {
	// 0-index for math, 1-index for position.
	return (pos-1)%10 + 1
}

type Roller interface {
	Roll() int
}

type DD100 struct{ val int }

func (d *DD100) Roll() int {
	val := d.val
	d.val = (d.val + 1) % 100
	return val + 1
}

func part2(p1, p2 int) int {
	active := make(StateCounts)
	active[State{p1, p2, 0, 0}] = 1

	done := make(map[State]int)

	for len(active) > 0 {
		state, count := active.Pop()
		nextActive, nextDone := state.Successors()
		for next, extra := range nextActive {
			active[next] += count * extra
		}
		for next, extra := range nextDone {
			done[next] += count * extra
		}
	}

	w1, w2 := 0, 0
	for state, count := range done {
		if state.Win1() {
			w1 += count
		} else {
			w2 += count
		}
	}
	return max(w1, w2)
}

type StateCounts map[State]int

func (sc StateCounts) Pop() (State, int) {
	for state, count := range sc {
		delete(sc, state)
		return state, count
	}
	panic("Pop from empty map")
}

func (sc StateCounts) Total() (count int) {
	for _, c := range sc {
		count += c
	}
	return
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

type State struct {
	p1, p2 int
	s1, s2 int
}

func (s State) Done() bool {
	return s.s1 >= 21 || s.s2 >= 21
}

func (s State) Win1() bool {
	return s.s1 >= 21
}

var diracDie = []int{1, 2, 3}
var diracRolls = makeDiracRolls()

func makeDiracRolls() (rolls []int) {
	for _, r1 := range diracDie {
		for _, r2 := range diracDie {
			for _, r3 := range diracDie {
				rolls = append(rolls, r1+r2+r3)
			}
		}
	}
	return
}

func (s State) Successors() (active StateCounts, done StateCounts) {
	active, done = make(StateCounts), make(StateCounts)
	for _, r1 := range diracRolls {
		t1 := s.P1(r1)
		if t1.Done() {
			done[t1]++
			continue
		}
		for _, r2 := range diracRolls {
			t2 := t1.P2(r2)
			if t2.Done() {
				done[t2]++
				continue
			}
			active[t2]++
		}
	}
	return
}

func (s State) P1(roll int) State {
	next := s
	next.p1 = move(s.p1, roll)
	next.s1 = s.s1 + score(next.p1)
	return next
}

func (s State) P2(roll int) State {
	next := s
	next.p2 = move(s.p2, roll)
	next.s2 = s.s2 + score(next.p2)
	return next
}
