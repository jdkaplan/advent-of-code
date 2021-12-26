package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"time"

	"github.com/jdkaplan/advent-of-code/aoc"
)

func main() {
	lines := aoc.Input().ReadLines("day24.txt")

	prog := parseInput(lines)
	steps := decompile(prog)

	seed := time.Now().Unix()
	if ok := checkSteps(prog, steps, seed); !ok {
		fmt.Println("Difference found! Seed: ", seed)
	}

	fmt.Println(part1(steps))
	fmt.Println(part2(steps))
}

func decompile(prog Program) (steps Steps) {
	for _, block := range prog {
		steps = append(steps, NewStep(block))
	}
	return
}

type Equation struct{ i, d int }

func part1(steps Steps) int {
	var inp [14]int
	var ups []Equation

	for i, step := range steps {
		switch step.zDiv {
		case 1:
			ups = append([]Equation{{i, step.yOff}}, ups...)
		case 26:
			up := ups[0]
			ups = ups[1:]
			dn := Equation{i, -step.xOff}
			u, d := maxSolution(dn.d - up.d)
			inp[up.i] = u
			inp[dn.i] = d
		default:
			panic(step.zDiv)
		}
	}

	if steps.Run(inp[:], false) == 0 {
		return reassemble(inp)
	}
	return -1
}

func part2(steps Steps) int {
	var inp [14]int
	var ups []Equation

	for i, step := range steps {
		switch step.zDiv {
		case 1:
			ups = append([]Equation{{i, step.yOff}}, ups...)
		case 26:
			up := ups[0]
			ups = ups[1:]
			dn := Equation{i, -step.xOff}
			u, d := minSolution(dn.d - up.d)
			inp[up.i] = u
			inp[dn.i] = d
		default:
			panic(step.zDiv)
		}
	}

	if steps.Run(inp[:], false) == 0 {
		return reassemble(inp)
	}
	return -1
}

func reassemble(ds [14]int) (n int) {
	for _, d := range ds {
		n *= 10
		n += d
	}
	return
}

func maxSolution(d int) (i, j int) {
	for i := 9; i >= 1; i-- {
		for j := 9; j >= 1; j-- {
			if i-j == d {
				return i, j
			}
		}
	}
	return 0, 0
}

func minSolution(d int) (i, j int) {
	for i := 1; i <= 9; i++ {
		for j := 1; j <= 9; j++ {
			if i-j == d {
				return i, j
			}
		}
	}
	return 0, 0
}

type Step struct{ zDiv, xOff, yOff int }

func NewStep(block Block) Step {
	div := block[4].(BinopN)
	assert(div.op, "div")
	assert(div.a, "z")
	zDiv := div.b

	xAdd := block[5].(BinopN)
	assert(xAdd.op, "add")
	assert(xAdd.a, "x")
	xOff := xAdd.b

	yAdd := block[15].(BinopN)
	assert(yAdd.op, "add")
	assert(yAdd.a, "y")
	yOff := yAdd.b

	return Step{zDiv, xOff, yOff}
}

func (s Step) String() string {
	return fmt.Sprintf("z0: %2d, x0: %3d, y0: %2d", s.zDiv, s.xOff, s.yOff)
}

func (s Step) Run(inp, z int) int {
	m := z / s.zDiv
	if z%26+s.xOff == inp {
		return m
	} else {
		return 26*m + s.yOff + inp
	}
}

func checkSteps(prog Program, steps Steps, seed int64) (ok bool) {
	ok = true
	rand.Seed(seed)
	for i := 0; i < 10; i++ {
		inp := randInput()
		actual := prog.Run(inp, false)
		hacked := steps.Run(inp, false)
		if actual != hacked {
			fmt.Println("Input:", inp)
			fmt.Println("Actual:", actual)
			fmt.Println("Hacked:", hacked)
			ok = false
		}
	}
	return
}

func randInput() (inputs []int) {
	for i := 0; i < 14; i++ {
		inputs = append(inputs, rand.Intn(9)+1)
	}
	return
}

func parseInput(lines []string) Program {
	var is []Instruction
	for _, line := range lines {
		f := strings.Fields(line)
		switch op := f[0]; op {
		case "inp":
			is = append(is, Inp{f[1]})
		case "add", "mul", "div", "mod", "eql":
			if b, err := strconv.Atoi(f[2]); err == nil {
				is = append(is, BinopN{op, f[1], b})
			} else {
				is = append(is, BinopV{op, f[1], f[2]})
			}
		default:
			panic(op)
		}
	}
	return split(is)
}

func split(is []Instruction) []Block {
	var blocks []Block
	var block []Instruction
	for len(is) > 0 {
		i := is[0]
		is = is[1:]
		if _, ok := i.(Inp); ok {
			blocks = append(blocks, block)
			block = nil
		}
		block = append(block, i)
	}
	blocks = append(blocks, block)
	if len(blocks[0]) > 0 {
		panic("oops")
	}
	return blocks[1:]
}

type Program []Block

func (p Program) String() string {
	var sb strings.Builder
	for _, b := range p {
		fmt.Fprintln(&sb, b)
	}
	return sb.String()
}

type Block []Instruction

func (b Block) String() string {
	var sb strings.Builder
	for _, line := range b {
		fmt.Fprintln(&sb, line)
	}
	return sb.String()
}

func (p Program) Run(inputs []int, log bool) int {
	var program []Instruction
	for _, block := range p {
		program = append(program, block...)
	}

	mem := &Memory{}
	for i, inp := range inputs {
		if log {
			fmt.Println(i, "|", inp, state(mem.z))
		}
		mem, program = tick(inp, mem, program)
		if len(program) == 0 {
			return mem.z
		}
	}
	panic("EOF")
}

func state(z int) string {
	var m []int
	for z > 26 {
		m = append(m, z/26)
		z /= 26
	}
	return fmt.Sprintf("%v, %d", m, z)
}

type Steps []Step

func (s Steps) Run(inputs []int, log bool) int {
	steps := s[:]
	z := 0
	for i, inp := range inputs {
		step := steps[0]
		steps = steps[1:]
		if log {
			fmt.Println(i, "|", inp, state(z))
		}
		z = step.Run(inp, z)
		if len(steps) == 0 {
			return z
		}
	}
	panic("EOF")
}

func tick(input int, mem *Memory, program []Instruction) (*Memory, []Instruction) {
	ii, ok := program[0].(Inp)
	if !ok {
		panic(program[0])
	}
	mem.Write(ii.a, input)
	program = program[1:]

	for lno, i := range program {
		switch i := i.(type) {
		case Inp:
			return mem, program[lno:]
		case BinopV:
			a, b := mem.Read(i.a), mem.Read(i.b)
			mem.Write(i.a, apply(i.op, a, b))
		case BinopN:
			a, b := mem.Read(i.a), i.b
			mem.Write(i.a, apply(i.op, a, b))
		default:
			panic(i)
		}
	}
	return mem, nil
}

type Memory struct {
	w, x, y, z int
}

func (m Memory) Read(name string) int {
	switch name {
	case "w":
		return m.w
	case "x":
		return m.x
	case "y":
		return m.y
	case "z":
		return m.z
	default:
		panic(name)
	}
}

func (m *Memory) Write(name string, value int) {
	switch name {
	case "w":
		m.w = value
	case "x":
		m.x = value
	case "y":
		m.y = value
	case "z":
		m.z = value
	default:
		panic(name)
	}
}

type Instruction interface {
	instruction()
	fmt.Stringer
}

type Inp struct {
	a string
}

func (Inp) instruction() {}
func (i Inp) String() string {
	return fmt.Sprintf("%s <- inp", i.a)
}

var opSign = map[string]string{
	"add": "+",
	"mul": "*",
	"div": "/",
	"mod": "%",
	"eql": "==",
}

type BinopV struct {
	op   string
	a, b string
}

func (BinopV) instruction() {}
func (b BinopV) String() string {
	return fmt.Sprintf("%s = %s %s %s", b.a, b.a, opSign[b.op], b.b)
}

type BinopN struct {
	op string
	a  string
	b  int
}

func (BinopN) instruction() {}
func (b BinopN) String() string {
	return fmt.Sprintf("%s = %s %s %d", b.a, b.a, opSign[b.op], b.b)
}

func apply(op string, a, b int) int {
	switch op {
	case "add":
		return a + b
	case "mul":
		return a * b
	case "div":
		if b == 0 {
			panic("divide by zero")
		}
		return a / b
	case "mod":
		if a < 0 {
			panic(fmt.Sprintf("negative divisor: %d", a))
		}
		if b <= 0 {
			panic(fmt.Sprintf("nonpositive modulus: %d", b))
		}
		return a % b
	case "eql":
		if a == b {
			return 1
		}
		return 0
	default:
		panic(op)
	}
}

func assert(actual, expected interface{}) {
	if actual != expected {
		panic(fmt.Sprintf("Expected %s, got %s", expected, actual))
	}
}
