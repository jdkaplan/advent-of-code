~ "aoc.ua" ~ Lines Sections

Sections &fras "input/day05.txt"
⍚Lines
°[□⊙□⊙]

≡(⊂∩⋕°$"_-_")
Ranges ←

≡⋕
Items ←

Contains ← ×⊃(≤⊙⊢|≥⊙⊣)

Part₁ ← /+ ≡(>₀/+) ⊞Contains Items

# Overlaps ? A B
Overlap ← ≤ ⊣ ⊙⊢

# Range ? A B
Join ← ⊂⊃(/↧⊂⊢⊙⊢|/↥⊂⊣⊙⊣)

Part₂ ← (
  ⍢(
  | # Changed Ranges' ? Ranges
    ⍆
    ⊸(↘₋₁⟜↘₁)
    ˜⊂0≡Overlap
    ˜⨂ 1
    ⤚≠ ⊙⊸⧻
    ⨬(⋅0
    | ⊃(↙
      | ¤ Join °⊟⊏ ⊂⟜+₁
      | ↘+₂)
      ⊂⊂
      1
    )
  )
  /+ ≡(+₁ -⊃⊢⊣)
)

Part₁ Ranges
Part₂ Ranges
