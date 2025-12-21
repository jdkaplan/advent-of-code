~ "aoc.ua" ~ Lines

Input     ← Lines &fras "input/day08.txt"
Junctions ← ≡◇⊜⋕ ⊸≠@, Input

Distance ← √ /+ ⁿ2 -
Dist₂    ← /+ ⁿ2 -

Part₁ ← (
  ⊙⟜≡(□¤)
  ⊙(
    °⊏
    ⊏ ⧅< 2
    ⊏⍏⊸≡(Distance°[⊙⊙])
  )
  ⟜↙

  ⊙⊃(⋅∘|∘)

  ⍥(
    ⊙⊃(¤⊢|↘1)
    ⤚≡(/↥◇∊)
    ⊃(▽|▽¬)
    /⍚⊂
    ⊂
  )

  ⊙(˙⍤=0⧻)

  /×↙¯3⍆≡◇⧻
)

Part₂ ← (
  ⟜≡(□¤)
  ⊏ ⧅< 2 °⊏
  ⊏⍏⊸≡(Distance°[⊙⊙])

  # Edges Forest
  ⊃(⋅∘|∘)
  # Forest Edges 0

  ⍢(⊙⊃(¤⊢|↘1|×∩⊢°[⊙⊙]⊢)
    ⤚≡(/↥◇∊)
    ⊃(▽|▽¬)
    /⍚⊂
    ⊂
  | >1◇⧻
  )
  ⊣
)

&s Part₁ 1000 Junctions
&s Part₂ Junctions
