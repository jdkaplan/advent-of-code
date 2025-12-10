~ "aoc.ua" ~ Lines

Input ← (
  &fras "input/day02.txt"
  °□ ⊢Lines
  ⊜□ ⊸≠ @,
)

ParseRange ← (
  ⊜□ ⊸≠ @,
  ⍚(⊂∩⋕°$"_-_")
  °□⊢
)

Seq       ← + ⊙⇡ ⟜(+1-)
NumDigits ← ⧻⊥10

Chunks ← (
  ↯ 1_1
  ⊙(⊥10)
  ⧈(⌝⊥10)
)

Pattern ← (
  Chunks
  =1⧻◴
)

ValidIdWindow ← (
  ⊙(⊸NumDigits)
  ⤚(=0◿)
  ⨬(1⋅⋅|¬Pattern)
)

ValidId₁ ← (
  ⟜(⍤⤙≍ [] △)
  ⊸NumDigits
  ⊸(◿2)
  ⨬(ValidIdWindow÷2|1⋅⋅)
)

ValidId₂ ← (
  ⟜(⍤⤙≍ [] △)
  ⊸(+1 ⇡ ⌊÷2NumDigits)
  ≡ValidIdWindow
  ¬˜∊0
)

Part₁ ← (
  ⍚(
    Seq°⊟
    ▽⊸≡(¬ValidId₁)
    /+
  )
  /◇+
)

Part₂ ← (
  ⍚(
    Seq°⊟
    ▽⊸≡(¬ValidId₂)
    /+
  )
  /◇+
)

Ranges ← ⍚ParseRange Input

Part₁ Ranges
Part₂ Ranges
