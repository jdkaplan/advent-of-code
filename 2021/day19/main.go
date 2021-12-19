package main

import (
	"fmt"
	"log"
	"sort"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func init() {
	log.SetFlags(0)
}

func main() {
	text := aoc.Input().ReadFile("day19.txt")
	fmt.Println(part1(text))
}

func part1(text string) int {
	scanners := parseInput(text)

	offsets := make(map[int]Offset)
	offsets[0] = Offset{tx: V{0, 0, 0}, rot: noRot}

solve:
	for len(offsets) < len(scanners) {
		log.Println("Solved", len(offsets), "/", len(scanners))
		for _, s2 := range scanners {
			if _, ok := offsets[s2.id]; ok {
				// Already solved
				continue
			}

			for id, o1 := range offsets {
				s1 := scanners[id]
				tx2, r2, ok := match(s1, s2, 12)
				if ok {
					offsets[s2.id] = Offset{
						tx:  tx2.rot(o1.rot).plus(o1.tx),
						rot: rrot(o1.rot, r2),
					}
					continue solve
				}
			}
		}
	}
	return uniqPoints(scanners, offsets)
}

type Offset struct {
	tx  V
	rot R
}

func uniqPoints(scanners map[int]Scanner, offsets map[int]Offset) int {
	uniq := make(map[V]struct{})
	for _, s := range scanners {
		o := offsets[s.id]
		for p := range s.readings {
			u := p.rot(o.rot).plus(o.tx)
			uniq[u] = struct{}{}
		}
	}
	var ps []V
	for p := range uniq {
		ps = append(ps, p)
	}
	sort.Slice(ps, func(i, j int) bool {
		pi, pj := ps[i], ps[j]
		if pi.x != pj.x {
			return pi.x < pj.x
		}
		if pi.y != pj.y {
			return pi.y < pj.y
		}
		if pi.z != pj.z {
			return pi.z < pj.z
		}
		return false
	})
	return len(uniq)
}

func parseInput(text string) (scanners map[int]Scanner) {
	scanners = make(map[int]Scanner)
	for _, block := range strings.Split(text, "\n\n") {
		lines := strings.Split(block, "\n")

		var id int
		aoc.MustScan(lines[0], "--- scanner %d ---", &id)

		readings := make(map[V]struct{})
		for _, line := range lines[1:] {
			nums := strings.Split(line, ",")
			x := aoc.MustInt(nums[0])
			y := aoc.MustInt(nums[1])
			z := aoc.MustInt(nums[2])
			readings[V{x, y, z}] = struct{}{}
		}

		scanners[id] = Scanner{id, readings}
	}
	return
}

func match(s1, s2 Scanner, req int) (translation V, rotation R, ok bool) {
	for a1 := range s1.readings {
		for a2 := range s2.readings {
			for _, rot := range uniqRot {
				tx := a1.minus(a2.rot(rot))

				var matches int
				for p2 := range s2.readings {
					p1 := p2.rot(rot).plus(tx)
					if _, ok := s1.readings[p1]; ok {
						matches++
					}
				}

				if matches >= req {
					return tx, rot, true
				}
			}
		}
	}
	return V{}, R{}, false
}

type Scanner struct {
	id       int
	readings map[V]struct{}
}

type V struct{ x, y, z int }

func (v V) plus(u V) V {
	return V{v.x + u.x, v.y + u.y, v.z + u.z}
}

func (v V) minus(u V) V {
	return V{v.x - u.x, v.y - u.y, v.z - u.z}
}

func (v V) dot(u V) int {
	return v.x*u.x + v.y*u.y + v.z*u.z
}

func (v V) rot(r R) V {
	return rot(r, v)
}

type R struct {
	xx, xy, xz int
	yx, yy, yz int
	zx, zy, zz int
}

func rot(r R, v V) V {
	x := r.xx*v.x + r.xy*v.y + r.xz*v.z
	y := r.yx*v.x + r.yy*v.y + r.yz*v.z
	z := r.zx*v.x + r.zy*v.y + r.zz*v.z
	return V{x, y, z}
}

func rrot(r1, r2 R) R {
	rx := V{r1.xx, r1.xy, r1.xz}
	ry := V{r1.yx, r1.yy, r1.yz}
	rz := V{r1.zx, r1.zy, r1.zz}

	cx := V{r2.xx, r2.yx, r2.zx}
	cy := V{r2.xy, r2.yy, r2.zy}
	cz := V{r2.xz, r2.yz, r2.zz}

	return R{
		rx.dot(cx), rx.dot(cy), rx.dot(cz),
		ry.dot(cx), ry.dot(cy), ry.dot(cz),
		rz.dot(cx), rz.dot(cy), rz.dot(cz),
	}
}

var uniqRot []R = genUniqRot()

var noRot = R{
	1, 0, 0,
	0, 1, 0,
	0, 0, 1,
}

func genUniqRot() []R {
	id := R{
		1, 0, 0,
		0, 1, 0,
		0, 0, 1,
	}
	rx := R{
		1, 0, 0,
		0, 0, -1,
		0, 1, 0,
	}
	ry := R{
		0, 0, 1,
		0, 1, 0,
		-1, 0, 0,
	}
	rz := R{
		0, -1, 0,
		1, 0, 0,
		0, 0, 1,
	}

	uniq := make(map[R]struct{})

	push := func(ops ...R) {
		r := id
		for _, op := range ops {
			r = rrot(op, r)
		}
		uniq[r] = struct{}{}
	}

	rotations := []R{rx, ry, rz}

	push()
	for _, r1 := range rotations {
		push(r1)
		for _, r2 := range rotations {
			push(r1, r2)
			for _, r3 := range rotations {
				push(r1, r2, r3)
				for _, r4 := range rotations {
					push(r1, r2, r3, r4)
				}
			}
		}
	}

	var rs []R
	for r := range uniq {
		rs = append(rs, r)
	}
	return rs
}
