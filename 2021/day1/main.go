package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func part1(depths []int) int {
	inc := 0
	for i := 0; i < len(depths)-1; i++ {
		if depths[i+1] > depths[i] {
			inc++
		}
	}
	return inc
}

func part2(depths []int) int {
	inc := 0
	for i := 0; i < len(depths)-3; i++ {
		if depths[i+3] > depths[i] {
			inc++
		}
	}
	return inc
}

func main() {
	f, err := os.Open("./input/day1.txt")
	if err != nil {
		panic(err)
	}

	scanner := bufio.NewScanner(f)
	scanner.Split(bufio.ScanLines)
	var depths []int
	for scanner.Scan() {
		i, err := strconv.Atoi(scanner.Text())
		if err != nil {
			panic(err)
		}
		depths = append(depths, i)
	}

	fmt.Println(part1(depths))
	fmt.Println(part2(depths))
}
