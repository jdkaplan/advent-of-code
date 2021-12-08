package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
	"github.com/jdkaplan/advent-of-code/aoc/stringset"
)

func main() {
	lines := aoc.Input().ReadLines("day8.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) int {
	var count int
	for _, l := range lines {
		_, out := aoc.Cut(l, " | ")
		for _, p := range strings.Fields(out) {
			if _, ok := easy(p); ok {
				count++
			}
		}
	}
	return count
}

func part2(lines []string) int {
	var sum int
	for _, l := range lines {
		pats, out := aoc.Cut(l, " | ")
		d := infer(strings.Fields(pats))
		n, err := d.decode(strings.Fields(out))
		if err != nil {
			panic(err)
		}
		sum += n
	}
	return sum
}

func easy(segments string) (int, bool) {
	switch len(segments) {
	// 0 segments => {}
	// 1 segments => {}
	case 2:
		return 1, true
	case 3:
		return 7, true
	case 4:
		return 4, true
	case 7:
		return 8, true
	default:
		// 5 segments => {2, 3, 5}
		// 6 segments => {0, 6, 9}
		return -1, false
	}
}

//  AA
// B  C
//  DD
// E  F
//  GG
type Display struct {
	A, B, C, D, E, F, G string
}

func (d *Display) String() string {
	return strings.Join([]string{d.A, d.B, d.C, d.D, d.E, d.F, d.G}, " ")
}

func infer(pats []string) *Display {
	var one, four, seven, eight stringset.StringSet
	var fives, sixes []stringset.StringSet
	for _, pat := range pats {
		s := stringset.Runes(pat)
		switch len(s) {
		case 2:
			one = s
		case 3:
			seven = s
		case 4:
			four = s
		case 5:
			fives = append(fives, s)
		case 6:
			sixes = append(sixes, s)
		case 7:
			eight = s
		default:
			panic("WTF")
		}
	}
	a := seven.Minus(one)
	ifives := stringset.Intersect(fives...)
	g := ifives.Minus(seven.Union(four))
	d := ifives.Minus(a.Union(g))
	e := eight.Minus(four.Union(a).Union(g))
	five := stringset.Intersect(sixes...).Union(d)
	six := five.Union(e)
	c := eight.Minus(six)
	// good
	two := stringset.Union(a, c, d, e, g)
	var three stringset.StringSet
	for _, s := range fives {
		if s.Equal(five) || s.Equal(two) {
			continue
		}
		three = s
	}
	if len(three) == 0 {
		panic("WAT")
	}
	f := three.Minus(two)
	b := eight.Minus(stringset.Union(a, c, d, e, f, g))

	return &Display{
		A: a.Only(),
		B: b.Only(),
		C: c.Only(),
		D: d.Only(),
		E: e.Only(),
		F: f.Only(),
		G: g.Only(),
	}
}

func (d *Display) decode(pats []string) (int, error) {
	var n int
	for _, p := range pats {
		n *= 10
		x, err := d.decodeSingle(p)
		if err != nil {
			return -1, err
		}
		n += x
	}
	return n, nil
}

func (d *Display) decodeSingle(pat string) (int, error) {
	s := stringset.Runes(pat)
	t0 := stringset.Slice([]string{d.A, d.B, d.C, d.E, d.F, d.G})
	t1 := stringset.Slice([]string{d.C, d.F})
	t2 := stringset.Slice([]string{d.A, d.C, d.D, d.E, d.G})
	t3 := stringset.Slice([]string{d.A, d.C, d.D, d.F, d.G})
	t4 := stringset.Slice([]string{d.B, d.C, d.D, d.F})
	t5 := stringset.Slice([]string{d.A, d.B, d.D, d.F, d.G})
	t6 := stringset.Slice([]string{d.A, d.B, d.D, d.E, d.F, d.G})
	t7 := stringset.Slice([]string{d.A, d.C, d.F})
	t8 := stringset.Slice([]string{d.A, d.B, d.C, d.D, d.E, d.F, d.G})
	t9 := stringset.Slice([]string{d.A, d.B, d.C, d.D, d.F, d.G})
	if s.Equal(t0) {
		return 0, nil
	}
	if s.Equal(t1) {
		return 1, nil
	}
	if s.Equal(t2) {
		return 2, nil
	}
	if s.Equal(t3) {
		return 3, nil
	}
	if s.Equal(t4) {
		return 4, nil
	}
	if s.Equal(t5) {
		return 5, nil
	}
	if s.Equal(t6) {
		return 6, nil
	}
	if s.Equal(t7) {
		return 7, nil
	}
	if s.Equal(t8) {
		return 8, nil
	}
	if s.Equal(t9) {
		return 9, nil
	}
	return -1, fmt.Errorf("decode segments: %s", s)
}
