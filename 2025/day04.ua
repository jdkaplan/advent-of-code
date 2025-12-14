~ "aoc.ua" ~ Lines

Input ← Lines &fras "input/day04.txt"
Wall  ← ≡◇=@@ Input

# Removed ? Wall
Step ← |1 (
  /⊂ -₁⇡[3 3]
  ▽¬⍜⍉(⊡1)⊸⦷0_0

  /+ ⊸⬚0↻
  <4
  ×
)

# Removed Wall' ? Wall
Run ← |1.2 (
  ⍢(
  | ⊙(
      ⊸Step
      ⟜-
      /+♭
    )
    ⤙+
    ≠₀
  ) 0
)

Part₁ ← /+♭ Step
Part₂ ← ⊙◌ Run

Part₁ Wall
Part₂ Wall
