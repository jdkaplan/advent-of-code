~ "aoc.ua" ~ Lines

Input ← ⊜∘ ⊸≠ @\n &fras "input/day07.txt"
Input
⊃(
| =@^ ↘1
| =@S ⊢
)
Manifold ←
Beam     ←

Split ← +⊃(⬚0↻1|⬚0↻¯1)

# Count ? Manifold Beam
Part₁ ← (
  ⊙⊙0
  ∧(
    # Splitters Beam Count
    ⊸↧
    ⊸/+

    # Taken Splits Beam Count
    ⊃(⋅⊙∘|+⊙⋅⋅∘)
    # Splits Beam Count'

    ⊸Split
    ⊙-
    ≠₀+ # Beam' ? Forked Passthrough
    # Beam' Count'
  )
  ◌
)

# Count ? Manifold Beam
Part₂ ← (
  ∧(
    + ⊃(
    | Split ×⊸↧
    | ⍜▽(×0)
    )
  )
  /+
)

Part₁ Manifold Beam
Part₂ Manifold Beam
