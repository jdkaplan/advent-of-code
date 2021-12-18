package main

import (
	"fmt"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day18.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}

func part1(lines []string) int {
	var snails []*Node
	for _, line := range lines {
		snails = append(snails, Tree(line))
	}
	n := snails[0]
	for _, x := range snails[1:] {
		n = add(n, x)
		for n.Reduce() {
		}
	}
	return n.Magnitude()
}

func part2(lines []string) int {
	var pairs [][2]string
	for i := 0; i < len(lines)-1; i++ {
		for j := i + 1; j < len(lines); j++ {
			pairs = append(pairs,
				[2]string{lines[i], lines[j]},
				[2]string{lines[j], lines[i]},
			)
		}
	}

	max := 0
	for _, p := range pairs {
		a, b := Tree(p[0]), Tree(p[1])
		n := add(a, b)
		for n.Reduce() {
		}
		m := n.Magnitude()
		if m > max {
			max = m
		}
	}
	return max
}

func add(a, b *Node) *Node {
	n := Pair(a, b)
	link(a.B().Right(), b.A().Left())
	return n
}

type Node struct {
	v    *int
	a, b *Node
	l, r *Node
}

func Tree(line string) *Node {
	root, extra := parseNode(chars(line))
	if len(extra) > 0 {
		panic(extra)
	}

	q := queue(&root)
	for i := 0; i < len(q)-1; i++ {
		l, r := q[i], q[i+1]
		link(l, r)
	}

	return &root
}

func Leaf(v int) *Node {
	return &Node{v: &v}
}

func Pair(a, b *Node) *Node {
	return &Node{a: a, b: b}
}

func (n *Node) Magnitude() int {
	if n.IsLeaf() {
		return *n.v
	}
	return 3*n.a.Magnitude() + 2*n.b.Magnitude()
}

func (n *Node) A() *Node {
	for !n.IsLeaf() {
		n = n.a
	}
	return n
}

func (n *Node) B() *Node {
	for !n.IsLeaf() {
		n = n.b
	}
	return n
}

func (n *Node) Left() *Node {
	for n.l != nil {
		n = n.l
	}
	return n
}

func (n *Node) Right() *Node {
	for n.r != nil {
		n = n.r
	}
	return n
}

func (n Node) IsLeaf() bool {
	return n.v != nil
}

func (n Node) String() string {
	if n.IsLeaf() {
		return fmt.Sprintf("%d", *n.v)
	}
	return fmt.Sprintf("[%s,%s]", n.a, n.b)
}

func (n *Node) Reduce() bool {
	if n.Explode(0) {
		return true
	}
	return n.Split()
}

func (n *Node) Split() bool {
	if !n.IsLeaf() {
		if n.a.Split() {
			return true
		}
		if n.b.Split() {
			return true
		}
		return false
	}

	v := *(n.v)
	if v < 10 {
		return false
	}

	a := v / 2
	b := (v + 1) / 2
	n.a, n.b, n.v = Leaf(a), Leaf(b), nil
	link(n.l, n.a)
	link(n.a, n.b)
	link(n.b, n.r)
	return true
}

func (n *Node) Explode(depth int) bool {
	if n.IsLeaf() {
		return false
	}

	if n.a.Explode(depth + 1) {
		return true
	}
	if n.b.Explode(depth + 1) {
		return true
	}

	if depth < 4 {
		return false
	}

	if n.a.l != nil {
		*n.a.l.v += *n.a.v
	}
	if n.b.r != nil {
		*n.b.r.v += *n.b.v
	}
	zero := 0
	l, r := n.a.l, n.b.r
	n.a, n.b, n.v = nil, nil, &zero
	link(l, n)
	link(n, r)
	return true
}

func link(l, r *Node) {
	if l != nil {
		l.r = r
	}
	if r != nil {
		r.l = l
	}
}

func parseNode(line []rune) (Node, []rune) {
	if line[0] == '[' {
		return parsePair(line)
	}
	return parseLeaf(line)
}

func parsePair(line []rune) (Node, []rune) {
	_, line = consume('[', line)
	a, line := parseNode(line)
	_, line = consume(',', line)
	b, line := parseNode(line)
	_, line = consume(']', line)
	return Node{a: &a, b: &b}, line
}

func parseLeaf(line []rune) (Node, []rune) {
	d, line := line[0], line[1:]
	v := int(d - '0')
	return Node{v: &v}, line
}

func queue(n *Node) []*Node {
	if n.IsLeaf() {
		return []*Node{n}
	}
	return append(queue(n.a), queue(n.b)...)
}

func chars(s string) (runes []rune) {
	for _, r := range s {
		runes = append(runes, r)
	}
	return
}

func consume(expected rune, rs []rune) (rune, []rune) {
	r, rs := rs[0], rs[1:]
	if r != expected {
		panic(fmt.Sprintf("Expected %s, got %s", string(expected), string(r)))
	}
	return r, rs
}
