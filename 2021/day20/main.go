package main

import (
	"fmt"
	"strings"

	"github.com/fatih/color"
	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day20.txt")
	alg, img := parseInput(text)
	fmt.Println(run(alg, img, 2))
	fmt.Println(run(alg, img, 50))
}

func parseInput(text string) (Alg, Image) {
	alg, img := aoc.Cut(text, "\n\n")
	lines := strings.Split(img, "\n")
	return NewAlg(alg), NewImage(lines)
}

func run(alg Alg, img Image, n int) int {
	for i := 0; i < n; i++ {
		img = tick(alg, img)
	}
	return len(img.light)
}

func tick(alg Alg, img Image) Image {
	light := make(map[RC]struct{})
	for r := img.rmin - 1; r <= img.rmax+1; r++ {
		for c := img.cmin - 1; c <= img.cmax+1; c++ {
			rc := RC{r, c}
			x := img.Next(rc)
			if alg.Apply(x) {
				light[rc] = struct{}{}
			}
		}
	}

	return Image{
		light,
		!img.border,
		img.rmin - 1, img.rmax + 1,
		img.cmin - 1, img.cmax + 1,
	}
}

type RC struct{ r, c int }

type Image struct {
	light      map[RC]struct{}
	border     bool
	rmin, rmax int
	cmin, cmax int
}

func NewImage(lines []string) (img Image) {
	img.rmin, img.rmax = 0, len(lines)
	img.cmin, img.cmax = 0, len(lines[0])
	img.light = make(map[RC]struct{})
	for r, line := range lines {
		for c, char := range line {
			if lightChar(char) {
				img.light[RC{r, c}] = struct{}{}
			}
		}
	}
	return
}

func (i Image) String() string {
	var sb strings.Builder
	pad := 4
	dim, bright := color.New(color.FgWhite), color.New(color.FgHiWhite)
	for r := i.rmin - pad; r <= i.rmax+pad; r++ {
		for c := i.cmin - pad; c <= i.cmax+pad; c++ {
			rc := RC{r, c}
			f := dim
			if i.Inbounds(rc) {
				f = bright
			}
			if i.IsLight(rc) {
				f.Fprint(&sb, "#")
			} else {
				f.Fprint(&sb, ".")
			}
		}
		sb.WriteString("\n")
	}
	return sb.String()
}

func (i Image) IsLight(rc RC) bool {
	if i.Inbounds(rc) {
		_, ok := i.light[rc]
		return ok
	}
	return i.border
}

func (i Image) Inbounds(rc RC) bool {
	r, c := rc.r, rc.c
	return i.rmin <= r && r <= i.rmax && i.cmin <= c && c <= i.cmax
}

func (i Image) Next(rc RC) uint {
	var x uint
	for j, n := range rc.Neighbors() {
		if i.IsLight(n) {
			x |= 1 << (8 - j)
		}
	}
	return x
}

func (rc RC) Neighbors() []RC {
	r, c := rc.r, rc.c
	return []RC{
		{r - 1, c - 1}, {r - 1, c}, {r - 1, c + 1},
		{r, c - 1}, {r, c}, {r, c + 1},
		{r + 1, c - 1}, {r + 1, c}, {r + 1, c + 1},
	}
}

type Alg map[uint]struct{}

func NewAlg(line string) Alg {
	alg := make(Alg)
	for i := uint(0); i < uint(len(line)); i++ {
		if lightChar(rune(line[i])) {
			alg[i] = struct{}{}
		}
	}
	return alg
}

func (a Alg) Apply(n uint) (light bool) {
	_, ok := a[n]
	return ok
}

func lightChar(r rune) bool {
	switch r {
	case '#':
		return true
	case '.':
		return false
	default:
		panic(r)
	}
}
