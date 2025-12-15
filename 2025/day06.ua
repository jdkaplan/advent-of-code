~ "aoc.ua" ~ Lines Words

Input ← &fras "input/day06.txt"

Part₁ ← (
  Lines
  ⍚Words
  ⍜↘₋₁ ⍚◇⋕
  ≡°□

  ⍉
  ↻0_¯1
  ≡(
    ⍣(⍩(/×) °(⊂□"*")
    | ⍩(/+) °(⊂□"+")
    )
    °□
  )
  /+
)

Part₂ ← (
  Lines
  ⬚@\s≡°□
  ⍉

  ⊜□ ¬⊸≡(⧻ regex "^\\s+$")
  ≡◇(
    ⟜≡(⋕ ⊡ 0_0 regex "\\d+" ↘¯1)
    ≡⊣
    ⊡ 0_0 regex "\\*|\\+"
    ⍣(⍩(/×) °(□"*")
    | ⍩(/+) °(□"+")
    )
  )
  /+
)

Part₁ Input
Part₂ Input
