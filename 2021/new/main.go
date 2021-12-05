package main

import (
	_ "embed"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"text/template"
)

//go:embed main.tmpl
var content string

type Data struct{ N int }

func main() {
	if err := Main(); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}

func Main() error {
	t, err := template.New("main").Parse(content)
	if err != nil {
		return err
	}

	n, err := strconv.Atoi(os.Args[1])
	if err != nil {
		return err
	}

	dir := fmt.Sprintf("day%d", n)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}

	main := filepath.Join(dir, "main.go")
	if err := writeMain(t, Data{N: n}, main); err != nil {
		return err
	}

	input := filepath.Join("input", fmt.Sprintf("day%d.txt", n))
	if err := touch(input); err != nil {
		return err
	}
	return nil
}

func writeMain(t *template.Template, data Data, path string) error {
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644)
	if err != nil {
		return err
	}
	// Prefer the write error over the close error.
	werr := t.Execute(f, data)
	cerr := f.Close()
	if werr != nil {
		return werr
	}
	return cerr
}

func touch(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	return f.Close()
}
