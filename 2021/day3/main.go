package main

import (
	"fmt"
	"strconv"

	"github.com/jdkaplan/advent-of-code/aoc"
)

const bits = 12

func part1(lines []string) uint {
	var count [bits]int
	for _, line := range lines {
		for i, char := range line {
			// Fix the index to be from the right
			i := bits - i - 1
			switch char {
			case '0':
				count[i]--
			case '1':
				count[i]++
			default:
				panic(char)
			}
		}
	}

	var gamma uint
	var epsilon uint
	for i, c := range count {
		mask := uint(1 << i)
		if c > 0 {
			gamma |= mask
			epsilon &= ^mask
		} else {
			gamma &= ^mask
			epsilon |= mask
		}
	}

	return gamma * epsilon
}

func partition(lines []string, idx int) (zeros []string, ones []string) {
	for _, line := range lines {
		char := line[idx]
		switch char {
		case '0':
			zeros = append(zeros, line)
		case '1':
			ones = append(ones, line)
		default:
			panic(char)
		}
	}
	return
}

func mustBin(s string) uint {
	u, err := strconv.ParseUint(s, 2, 0)
	if err != nil {
		panic(err)
	}
	return uint(u)
}

func part2(lines []string) int {
	oxy, co2 := lines, lines
	for i := 0; i < bits && len(oxy) > 1; i++ {
		zeros, ones := partition(oxy, i)
		if len(ones) >= len(zeros) {
			oxy = ones
		} else {
			oxy = zeros
		}
	}
	for i := 0; i < bits && len(co2) > 1; i++ {
		zeros, ones := partition(co2, i)
		if len(ones) >= len(zeros) {
			co2 = zeros
		} else {
			co2 = ones
		}
	}
	return int(mustBin(oxy[0]) * mustBin(co2[0]))
}

func main() {
	lines := aoc.ReadLines("./input/day3.txt")
	fmt.Println(part1(lines))
	fmt.Println(part2(lines))
}
