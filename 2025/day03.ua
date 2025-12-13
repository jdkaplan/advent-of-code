~ "aoc.ua" ~ Lines

Input ← Lines &fras "input/day03.txt"
Banks ← ⍚(≡⋕) Input

# Arr ? Lo Hi
Range ← (
  ◡<
  ⨬(+ ⊙⇡ ⟜-|[])
)

# Arr ? Hi Lo Arr
Slice ← (
  ⊸˜-
  ↙⊙↘
)

# Jolts ? Idx Bank
Jolts ← ⌝⊥10 ⇌ ⊏

# Jolts ? Idx Len Bank
Joltage′ ← |3 (
  ◡⋅≠₀
  ⨬(Jolts⊙⋅∘
  | |3 ⊸(=₀⧻)      # Empty Idx ? Idx
       ⨬(⊸(+₁⊣)|0) # Next Idx ? Empty Idx

       ⊙⊙-₁     # _ _ Len' ? _ _ Len
       ◡⋅⋅(-⊙⧻) # End _ _ Len' Bank ? _ _ Len' Bank
       Slice⊙⊙◡⋅⋅(≡⊟°⊏)
       °⊟⍉
       ⊙(⊢⍖)
       ˜⊡
       ˜⊂
       Joltage′
  )
)

# Jolts ? Len Bank
Joltage ← |2 Joltage′ []

Part₁ ← /+ ≡(Joltage 2 °□)
Part₂ ← /+ ≡(Joltage 12°□)

Part₁ Banks
Part₂ Banks
