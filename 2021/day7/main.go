package main

import (
	"fmt"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day7.txt")
	fmt.Println(part1(text))
	fmt.Println(part2(text))
}

func part1(text string) int {
	ps := aoc.Ints(text)
	argmin := ps[0]
	min := cost1(argmin, ps)
	for _, p := range ps[1:] {
		c := cost1(p, ps)
		if c < min {
			argmin, min = p, c
		}
	}
	fmt.Println("Pos:", argmin)
	return min
}

func part2(text string) int {
	ps := aoc.Ints(text)
	lo, hi := minmax(ps)
	cost, pos := bisect(func(p int) int { return cost2(p, ps) }, lo, hi)
	fmt.Println("Pos:", pos)
	return cost
}

func cost1(x int, ns []int) (cost int) {
	for _, n := range ns {
		cost += abs(n - x)
	}
	return
}

func cost2(x int, ns []int) (cost int) {
	for _, n := range ns {
		d := abs(n - x)
		cost += tri(d)
	}
	return
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

func tri(n int) int {
	return n * (n + 1) / 2
}

func bisect(f func(int) int, lo, hi int) (min int, argmin int) {
	if lo == hi {
		return f(lo), lo
	}
	if hi-lo == 1 {
		flo, fhi := f(lo), f(hi)
		if flo < fhi {
			return flo, lo
		}
		return fhi, hi
	}
	md := (hi + lo) / 2
	switch md {
	case lo:
		return f(lo), lo
	case hi:
		return f(hi), hi
	default:
		s := slope(f, md)
		if s == 0 {
			return f(md), md
		}
		if s < 0 {
			return bisect(f, md, hi)
		}
		return bisect(f, lo, md)
	}
}

func slope(f func(int) int, n int) int {
	var (
		lo  = n - 1
		hi  = n + 1
		flo = f(lo)
		fhi = f(hi)
	)
	return fhi - flo
}

func minmax(ns []int) (min int, max int) {
	min = ns[0]
	max = ns[0]
	for _, n := range ns[1:] {
		if n < min {
			min = n
		}
		if n > max {
			max = n
		}
	}
	return
}
