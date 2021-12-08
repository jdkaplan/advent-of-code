package stringset

import (
	"fmt"
	"sort"
	"strings"
)

type StringSet map[string]struct{}

func Slice(vals []string) StringSet {
	set := make(StringSet)
	for _, v := range vals {
		set[v] = struct{}{}
	}
	return set
}

func Runes(v string) StringSet {
	return Slice(strings.Split(v, ""))
}

func (s StringSet) String() string {
	var elts []string
	for e := range s {
		elts = append(elts, e)
	}
	sort.Strings(elts)
	return fmt.Sprintf("{%s}", strings.Join(elts, ", "))
}

func (s StringSet) Only() string {
	if len(s) > 1 {
		panic(fmt.Sprintf("too many elements: %s", s))
	}
	for v := range s {
		return v
	}
	panic("empty set")
}

func (s StringSet) Has(elt string) bool {
	_, ok := s[elt]
	return ok
}

func (s StringSet) add(elt string) {
	s[elt] = struct{}{}
}

func (s StringSet) Union(t StringSet) StringSet {
	set := make(StringSet)
	for a := range s {
		set.add(a)
	}
	for b := range t {
		set.add(b)
	}
	return set
}

func (s StringSet) Intersect(t StringSet) StringSet {
	set := make(StringSet)
	for a := range s {
		if t.Has(a) {
			set.add(a)
		}
	}
	return set
}

func (s StringSet) Minus(t StringSet) StringSet {
	set := make(StringSet)
	for a := range s {
		if !t.Has(a) {
			set.add(a)
		}
	}
	return set
}

func (s StringSet) Equal(t StringSet) bool {
	if len(s) != len(t) {
		return false
	}
	for a := range s {
		if !t.Has(a) {
			return false
		}
	}
	return true
}

func Union(sets ...StringSet) StringSet {
	t := make(StringSet)
	for _, s := range sets {
		t = t.Union(s)
	}
	return t
}

func Intersect(sets ...StringSet) StringSet {
	t := Union(sets...)
	for _, s := range sets {
		t = t.Intersect(s)
	}
	return t
}
