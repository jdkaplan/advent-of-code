package main

import (
	"fmt"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day21.txt")
	p1, p2 := parseInput(lines)
	fmt.Println(part1(p1, p2))
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
