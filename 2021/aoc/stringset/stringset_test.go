package stringset_test

import (
	"testing"

	"github.com/jdkaplan/advent-of-code/aoc/stringset"
)

func TestMinus(t *testing.T) {
	a := stringset.Runes("dab")
	b := stringset.Runes("ab")
	u := a.Minus(b)
	if n := len(u); n != 1 {
		t.Fatalf("Expected one value, got %d", n)
	}
	if v := u.Only(); v != "d" {
		t.Errorf(`Expected value to be "d", got %s`, v)
	}
}

func TestIntersect(t *testing.T) {
	t.Run("pairwise", func(t *testing.T) {
		u := stringset.Runes("dab").Intersect(stringset.Runes("ab"))
		expected := stringset.Runes("ab")
		if !u.Equal(expected) {
			t.Errorf(`Expected value to be %s, got %s`, expected, u)
		}
	})

	t.Run("multiple", func(t *testing.T) {
		u := stringset.Intersect(
			stringset.Runes("dab"),
			stringset.Runes("ab"),
		)
		expected := stringset.Runes("ab")
		if !u.Equal(expected) {
			t.Errorf(`Expected value to be %s, got %s`, expected, u)
		}
	})
}
