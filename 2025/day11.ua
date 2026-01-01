~ "aoc.ua" ~ Lines

Lines &fras "input/day11.txt"

⍚(
  °$"_: _"
  ⊙(◇⋕₃₆°/$"_ _")
  ⋕₃₆
  ≡⌞⊂
)
⍆ /◇⊂
Edges ←

# Queue ? Edges
TopoSort ← (
  $Edges

  °˜⊟ ⊸⍉
  ◴▽¬⊸∊
  $Queue

  ⊙($Nodes[])

  ⍢( # Queue Nodes Edges
    °⊂
    # N Queue' Nodes Edges
    ⊃(⊙∘|⊂⊙⋅∘)
    # N Queue' Nodes' Edges
    ◡(
      ⊕□ ⊸≡(≠⊙⊢) ⊙⋅⋅∘
      ∩°□ ⊃(⍣⊡[]0|⍣⊡[]1)
      ≡⊣
    )
    # Neighbors Edges' N Queue' Nodes' Edges
    ⊓($Neighbors|$Edges|◌|$Queue|$Nodes|◌)
    ◡(˜▽⟜(¬˜∊) ⊙≡⊣∘)
    ⊙◌
    ⊃($Queue ⊂⊙⋅∘|⋅⋅⋅∘|⋅∘)
  | >0⧻
  )

  ⋅⊙◌
)

# Count ? Edges End Start
Paths ← (
  ⊓($Edges|$End|$Start)
  $Queue ⊸TopoSort

  ⍢(↘1|≠⊢⊙⋅∘)

  # ⍢(↘¯1|≠⊣⊙⋅⋅∘)
  ⊙⊙◌

  ⟜($Counts insert⊢⊙(1 []))
  ↘1

  ⍢(°⊂
    # N Queue' Counts Edges
    ◡(⊙⋅⋅∘
      ▽⊸≡(=⊙⊢∘)
      ≡⊣
    )
    $Neighbors

    ◡(⊙⋅⋅⊙
      /+≡⌟(⍣get0)
    )
    ⊃(⋅⋅⋅∘|insert ⊃(⋅⋅∘|⊙⋅⋅⋅∘))
  | >0⧻
  )
  ⋅⊙◌
  ⍣˜get0
)

Part₁ ← Paths⊙(∩⋕₃₆ "out" "you")

Without ← ▽⊸≡(≠⊙⊢∘)

Part₂ ← (
  ⊃(
  | Paths ∧Without (◇⋕₃₆ {"out" "dac"}) ⊙(∩⋕₃₆ "fft" "svr")
  | Paths ∧Without (◇⋕₃₆ {"svr" "out"}) ⊙(∩⋕₃₆ "dac" "fft")
  | Paths ∧Without (◇⋕₃₆ {"fft" "svr"}) ⊙(∩⋕₃₆ "out" "dac")
  | Paths ∧Without (◇⋕₃₆ {"out" "fft"}) ⊙(∩⋕₃₆ "dac" "svr")
  | Paths ∧Without (◇⋕₃₆ {"svr" "out"}) ⊙(∩⋕₃₆ "fft" "dac")
  | Paths ∧Without (◇⋕₃₆ {"dac" "svr"}) ⊙(∩⋕₃₆ "out" "fft")
  )
  +⊓(××|××)
)

Part₁ Edges
Part₂ Edges
