package aoc

import (
	"bufio"
	"io"
	"io/fs"
	"os"
	"strconv"
	"strings"
)

func ReadLines(path string) (lines []string) {
	f, err := os.Open(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines
}

func ReadFile(path string) string {
	b, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return strings.TrimSpace(string(b))
}

func MustInt(s string) int {
	i, err := strconv.Atoi(s)
	if err != nil {
		panic(err)
	}
	return i
}

func MustHex(s string) int {
	i, err := strconv.ParseInt(s, 16, 0)
	if err != nil {
		panic(err)
	}
	return int(i)
}

type Inputs struct {
	fs fs.FS
}

func (i Inputs) ReadLines(path string) (lines []string) {
	f, err := i.fs.Open(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines
}

func (i Inputs) ReadFile(path string) string {
	f, err := i.fs.Open(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	b, err := io.ReadAll(f)
	if err != nil {
		panic(err)
	}
	return strings.TrimSpace(string(b))
}

func Input() Inputs {
	if len(os.Args) > 1 {
		return Inputs{os.DirFS(os.Args[1])}
	}
	return Inputs{os.DirFS("./input")}
}

// Cut will be added to strings in Go 1.18, so hack it in for now!
func Cut(s, sep string) (before, after string) {
	if i := strings.Index(s, sep); i >= 0 {
		return s[:i], s[i+len(sep):]
	}
	panic("Separator was not found in string")
}

func Ints(text string) (ns []int) {
	for _, n := range strings.Split(text, ",") {
		ns = append(ns, MustInt(n))
	}
	return
}

func ExLines(text string) []string {
	return strings.Split(strings.TrimSpace(text), "\n")
}
