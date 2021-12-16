package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day16.txt")
	b := parse(text)
	fmt.Println(part1(b))
	fmt.Println(part2(b))
}

type bits []int

func (b bits) String() string {
	var sb strings.Builder
	for _, x := range b {
		fmt.Fprintf(&sb, "%b", x)
	}
	return sb.String()
}

func (b bits) Uint() uint {
	var u uint
	for _, i := range b {
		u <<= 1
		u += uint(i)
	}
	return u
}

func (b bits) Consume(n uint) (prefix uint, extra bits) {
	return b[:n].Uint(), b[n:]
}

func parse(text string) (b bits) {
	for _, char := range strings.Split(text, "") {
		x := aoc.MustHex(char)
		for i := 3; i >= 0; i-- {
			b = append(b, (x>>i)&1)
		}
	}
	return
}

func part1(b bits) uint {
	p, _ := packet(b)
	return sumVersions(p)
}

func part2(b bits) uint {
	p, _ := packet(b)
	return p.Value()
}

func sumVersions(p Packet) uint {
	switch p := p.(type) {
	case Literal: // no-op
		return p.Version()
	case Operator:
		sum := p.Version()
		for _, inner := range p.Packets {
			sum += sumVersions(inner)
		}
		return sum
	default:
		panic(fmt.Sprintf("Unknown data type: %T", p))
	}
}

type Packet interface {
	Version() uint
	Type() uint
	Value() uint
}

type Literal struct {
	V, T uint
	Val  uint
}

func (l Literal) Version() uint { return l.V }
func (l Literal) Type() uint    { return l.T }
func (l Literal) Value() uint   { return l.Val }

type Operator struct {
	V, T    uint
	Packets []Packet
}

func (o Operator) Version() uint { return o.V }
func (o Operator) Type() uint    { return o.T }

func (o Operator) Value() uint {
	switch o.T {
	case 0: // sum
		var sum uint
		for _, p := range o.Packets {
			sum += p.Value()
		}
		return sum
	case 1: // product
		prod := uint(1)
		for _, p := range o.Packets {
			prod *= p.Value()
		}
		return prod
	case 2: // minimum
		min := o.Packets[0].Value()
		for _, p := range o.Packets[1:] {
			if v := p.Value(); v < min {
				min = v
			}
		}
		return min
	case 3: // maximum
		max := uint(0)
		for _, p := range o.Packets {
			if v := p.Value(); v > max {
				max = v
			}
		}
		return max
	case 4: // literal
		panic("Unexpected literal")
	case 5: // greater than
		if l := len(o.Packets); l != 2 {
			panic(fmt.Sprintf("Expected 2 packets, got %d", l))
		}
		v1 := o.Packets[0].Value()
		v2 := o.Packets[1].Value()
		if v1 > v2 {
			return 1
		} else {
			return 0
		}
	case 6: // less than
		if l := len(o.Packets); l != 2 {
			panic(fmt.Sprintf("Expected 2 packets, got %d", l))
		}
		v1 := o.Packets[0].Value()
		v2 := o.Packets[1].Value()
		if v1 < v2 {
			return 1
		} else {
			return 0
		}
	case 7: // equal to
		if l := len(o.Packets); l != 2 {
			panic(fmt.Sprintf("Expected 2 packets, got %d", l))
		}
		v1 := o.Packets[0].Value()
		v2 := o.Packets[1].Value()
		if v1 == v2 {
			return 1
		} else {
			return 0
		}
	default:
		panic(fmt.Sprintf("Unexpected type: %d", o.T))
	}
}

func packet(b bits) (Packet, bits) {
	v, b := b.Consume(3)
	t, b := b.Consume(3)
	switch t {
	case 4:
		var val uint
		val, b = literal(b)
		return Literal{v, t, val}, b
	default:
		var ps []Packet
		ps, b = operator(b)
		return Operator{v, t, ps}, b
	}
}

func literal(b bits) (uint, bits) {
	var val uint
	for {
		var n uint
		n, b = b.Consume(5)

		val <<= 4
		val += n & 0b01111

		if n&0b10000 == 0 {
			break
		}
	}
	return val, b
}

func operator(b bits) ([]Packet, bits) {
	lt, b := b.Consume(1)
	var ps []Packet
	if lt == 0 {
		var l uint
		l, b = b.Consume(15)
		taken := uint(0)
		for l-taken > 6 { // min length for a packet
			var p Packet
			oldlen := len(b)
			p, b = packet(b)
			ps = append(ps, p)
			taken += uint(oldlen - len(b))
		}
		b = padding(b, l-taken)
		return ps, b
	} else {
		var n uint
		n, b = b.Consume(11)
		for i := uint(0); i < n; i++ {
			var p Packet
			p, b = packet(b)
			ps = append(ps, p)
		}
		return ps, b
	}
}

func padding(b bits, n uint) bits {
	u, b := b.Consume(n)
	if u != 0 {
		panic(fmt.Sprintf("Expected padding, got nonzero bits: %b", u))
	}
	return b
}
