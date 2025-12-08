~ "aoc.ua" ~ Lines

Input ← Lines &fras "input/day01.txt"

Dirs ← ≡°□ +⊃(¯=@L) (=@R) ⍚⊢
Amts ← ⋕⍚(↘ 1)
Ops  ← × ⊃Dirs Amts

Part₁ ← (
  ⬚50\(◿100 +)
  /+ =0
)

Div         ← ⌊⌵÷
Rem         ← ×⊃(◿⊙⌵|±⋅)
DivRem      ← ⊂ ⊃(Div|Rem)
ChSgn       ← ≠∩±
NeitherZero ← |2 =0 +∩(=0)
CrossedZero ← |2 ×⊃(NeitherZero|ChSgn)
TouchedZero ← |2 × ≠0 ⊙(=0)

Update ← |2 Rem100 + Rem100      # op pos
Z₁     ← |2 Div100 ⊙◌            # op [pos]
Z₂     ← |2 Div100 +Rem100       # op pos
Z₃     ← |2 TouchedZero ⟜+Rem100 # op pos
Z₄     ← |2 CrossedZero ⟜+Rem100 # op pos

Part₂ ← (
  ⬚[0 50] /(|2
    ⊃(⊡0|⊡1)
    ⊙(⊂⊂⊂ ⊃(Z₁|Z₂|Z₃|Z₄|Update))
    ˜∧+
    ⊂
  )
  ⊢
)

Part₁ Ops Input
Part₂ Ops Input
