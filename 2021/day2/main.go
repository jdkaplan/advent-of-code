package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type position struct {
	h, d, aim int
}

func (p position) move1(op string, n int) position {
	switch op {
	case "forward":
		return position{h: p.h + n, d: p.d}
	case "up":
		return position{h: p.h, d: p.d - n}
	case "down":
		return position{h: p.h, d: p.d + n}
	}
	panic(fmt.Sprintf("Unknown operand: %s", op))
}

func part1(lines []string) int {
	var pos position
	for _, line := range lines {
		fs := strings.Fields(line)
		if len(fs) != 2 {
			panic(fs)
		}
		op := fs[0]
		n, err := strconv.Atoi(fs[1])
		if err != nil {
			panic(err)
		}
		pos = pos.move1(op, n)
	}
	return pos.h * pos.d
}

func (p position) move2(op string, n int) position {
	switch op {
	case "forward":
		return position{h: p.h + n, d: p.d + n*p.aim, aim: p.aim}
	case "up":
		return position{h: p.h, d: p.d, aim: p.aim - n}
	case "down":
		return position{h: p.h, d: p.d, aim: p.aim + n}
	}
	panic(fmt.Sprintf("Unknown operand: %s", op))
}

func part2(lines []string) int {
	var pos position
	for _, line := range lines {
		fs := strings.Fields(line)
		if len(fs) != 2 {
			panic(fs)
		}
		op := fs[0]
		n, err := strconv.Atoi(fs[1])
		if err != nil {
			panic(err)
		}
		pos = pos.move2(op, n)
	}
	return pos.h * pos.d
}

func main() {
	f, err := os.Open("./input/day2.txt")
	if err != nil {
		panic(err)
	}

	scanner := bufio.NewScanner(f)
	scanner.Split(bufio.ScanLines)
	var lines []string

	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}
