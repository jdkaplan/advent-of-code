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

type Re map[rune]map[rune]rune

func (r Re) Get(a, b rune) (rune, bool) {
	inner, ok := r[a]
	if !ok {
		return rune(0), false
	}
	ins, ok := inner[b]
	return ins, ok
}

func (r Re) Put(a, b, i rune) {
	inner, ok := r[a]
	if !ok {
		inner = make(map[rune]rune)
		r[a] = inner
	}
	inner[b] = i
}

func run(s string, rules []Rule, steps int) int {
	re := make(Re)
	for _, r := range rules {
		re.Put(r.a, r.b, r.i)
	}

	for i := 0; i < steps; i++ {
		s = expand(s, re)
	}

	counts := countChars(s)
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

func expand(s string, re Re) string {
	w := pairs(s)
	var sb strings.Builder
	for {
		a, b, err := w.Next()
		if errors.Is(err, io.EOF) {
			sb.WriteRune(a)
			break
		} else if err != nil {
			panic(err)
		}
		sb.WriteRune(a)
		if i, ok := re.Get(a, b); ok {
			sb.WriteRune(i)
		}
	}
	return sb.String()
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

func countChars(s string) map[rune]int {
	r := strings.NewReader(s)
	m := make(map[rune]int)
	for {
		c, _, err := r.ReadRune()
		if errors.Is(err, io.EOF) {
			return m
		} else if err != nil {
			panic(err)
		}
		m[c]++
	}
}
