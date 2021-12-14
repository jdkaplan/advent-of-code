package main

import (
	"errors"
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day14.txt")
	start, rules := parse(text)
	fmt.Println(run(start, rules, 10))
	fmt.Println(run(start, rules, 40))
}

type Rule struct {
	a, b, i rune
}

func parse(text string) (string, []Rule) {
	start, lines := aoc.Cut(text, "\n\n")
	var rules []Rule
	for _, l := range strings.Split(lines, "\n") {
		pair, ins := aoc.Cut(l, " -> ")
		a, b := (pair[0]), pair[1]
		rules = append(rules, Rule{rune(a), rune(b), rune(ins[0])})
	}
	return start, rules
}

type Pair [2]rune

type Re map[Pair]rune

func (r Re) Sub(p Pair) []Pair {
	ins, ok := r[p]
	if !ok {
		return []Pair{p}
	}
	p1 := Pair{p[0], ins}
	p2 := Pair{ins, p[1]}
	return []Pair{p1, p2}
}

func (r Re) Put(a, b, i rune) {
	r[Pair{a, b}] = i
}

func run(s string, rules []Rule, steps int) int {
	re := make(Re)
	for _, r := range rules {
		re.Put(r.a, r.b, r.i)
	}

	pc := make(map[Pair]int)
	for _, p := range allPairs(s) {
		pc[p]++
	}
	first := rune(s[0])

	for i := 0; i < steps; i++ {
		pc = expand(pc, re)
	}

	counts := make(map[rune]int)
	counts[first]++
	for p, c := range pc {
		counts[p[1]] += c
	}

	var chars []rune
	for r := range counts {
		chars = append(chars, r)
	}
	sort.Slice(chars, func(i, j int) bool {
		return counts[chars[i]] < counts[chars[j]]
	})
	min, max := chars[0], chars[len(chars)-1]
	return counts[max] - counts[min]
}

func allPairs(s string) []Pair {
	var out []Pair
	w := pairs(s)
	for {
		a, b, err := w.Next()
		if errors.Is(err, io.EOF) {
			return out
		} else if err != nil {
			panic(err)
		}
		out = append(out, Pair{a, b})
	}
}

func expand(pc map[Pair]int, re Re) map[Pair]int {
	out := make(map[Pair]int)
	for p, c := range pc {
		for _, b := range re.Sub(p) {
			out[b] += c
		}
	}
	return out
}

type Window struct {
	prev rune
	r    *strings.Reader
}

func (w *Window) Next() (a rune, b rune, err error) {
	a = w.prev
	b, _, err = w.r.ReadRune()
	w.prev = b
	return
}

func pairs(s string) *Window {
	w := &Window{r: strings.NewReader(s)}
	_, _, err := w.Next()
	if err != nil {
		panic(err)
	}
	return w
}
