package main

import (
	"fmt"
	"strings"

	"github.com/fatih/color"
	"github.com/jdkaplan/advent-of-code/aoc"
)

type input struct {
	numbers []int
	boards  []board
}

func parseInput(text string) input {
	sections := strings.Split(text, "\n\n")
	var nums []int
	for _, n := range strings.Split(sections[0], ",") {
		nums = append(nums, aoc.MustInt(n))
	}
	var boards []board
	for _, block := range sections[1:] {
		b := newBoard()
		for r, row := range strings.Split(block, "\n") {
			for c, n := range strings.Fields(row) {
				b.nums[r][c] = aoc.MustInt(n)
			}
		}
		boards = append(boards, b)
	}
	return input{numbers: nums, boards: boards}
}

type board struct {
	nums   *[5][5]int
	marked *[5][5]bool
	won    bool
}

func newBoard() board {
	return board{
		nums:   &[5][5]int{},
		marked: &[5][5]bool{},
	}
}

func (b board) String() string {
	var s strings.Builder
	for r, row := range b.nums {
		for c, n := range row {
			if b.marked[r][c] {
				color.New(color.FgGreen, color.Bold).Fprintf(&s, "%2d ", n)
			} else {
				fmt.Fprintf(&s, "%2d ", n)
			}
		}
		s.WriteRune('\n')
	}
	return s.String()
}

func (b *board) call(x int) (win bool) {
	if b.won {
		return false
	}
	for r, row := range b.nums {
		for c, n := range row {
			if n == x {
				b.marked[r][c] = true
				if b.win(r, c) {
					return true
				}
			}
		}
	}
	return
}

func (b board) win(r, c int) bool {
	return b.winRow(r) || b.winCol(c)
}

func (b board) winRow(r int) bool {
	for c := 0; c < 5; c++ {
		if !b.marked[r][c] {
			return false
		}
	}
	return true
}

func (b board) winCol(c int) bool {
	for r := 0; r < 5; r++ {
		if !b.marked[r][c] {
			return false
		}
	}
	return true
}

func (b board) score(x int) int {
	var sum int
	for r, row := range b.nums {
		for c, n := range row {
			if !b.marked[r][c] {
				sum += n
			}
		}
	}
	return x * sum
}

func part1(text string) int {
	inp := parseInput(text)
	for _, n := range inp.numbers {
		for _, b := range inp.boards {
			if b.call(n) {
				return b.score(n)
			}
		}
	}
	return len(inp.numbers)
}

func part2(text string) int {
	inp := parseInput(text)
	var wins int
	for _, n := range inp.numbers {
		for i, b := range inp.boards {
			if b.call(n) {
				// Set on the original in inp, not the copy in b.
				inp.boards[i].won = true
				wins++
				if wins == len(inp.boards) {
					return b.score(n)
				}
			}
		}
	}
	return len(inp.numbers)
}

func main() {
	text := aoc.ReadFile("./input/day4.txt")
	fmt.Println(part1(text))
	fmt.Println(part2(text))
}
