~ "aoc.ua" ~ Lines

Lines &fras "input/day11.txt"
≡◇(
  ∩□ °$"_: _"
)
⊙≡◇(□ °/$"_ _")
map

0
{["you"]}
⍢(⊃(⊢∘|↘1∘|⋅⊙∘)
  # Path Agenda' Count Edges
  ≍"out"⊸◇⊢
  ⨬(◡⊃(◇⊢|⋅⋅⋅∘)
    °□get
    ≡⌟⍚⊂
    ⊂
  | ⋅⊙⊃(+1∘|⋅∘)
  )
| >0 ⧻
)
⋅⊙◌
