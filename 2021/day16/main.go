package main

import (
	"fmt"
	"strings"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	text := aoc.Input().ReadFile("day16.txt")
	fmt.Println(part1(parse(text)))
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
}

type Literal struct {
	V, T  uint
	Value uint
}

func (l Literal) Version() uint { return l.V }
func (l Literal) Type() uint    { return l.T }

type Operator struct {
	V, T    uint
	Packets []Packet
}

func (o Operator) Version() uint { return o.V }
func (o Operator) Type() uint    { return o.T }

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
