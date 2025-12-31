~ "aoc.ua" ~ Lines

&fras "input/day10.txt"
Lines
≡(
  {°$"[_] _ {_}"}
  ⍜(°□⊡0|=@#)
  ⍜(°□⊡1|⍚⋕ ⍚°/$"_,_" ⍚°$"(_)" °/$"_ _")
  ⍜(°□⊡2|◇⋕ °/$"_,_")
)
Machines ←

Lights ← (
  ⊃(°□⊡0|°□⊡1)
  path(
    ≡⌞(
      ⊙◇°⊚
      ⬚0+
      ◿2
    )
  | /↧ =0)
  ⬚∞(-1 ⧻⊢)
)

Joltages ← (
  ⊃(°□⊡1|°□⊡2)
  ⬚0≡◇°⊚
  ⍉
)

Vars ← ≡(□ $"x_") ⇡⧻₁

Declarations ← (
  Vars
  ≡(&w $"(declare-const _ Int)\n")
)

Assertions ← (
  Vars
  ◡(&w $"(assert (= presses (+ _)))\n" /$"_ _")
  ≡(&w $"(assert (<= 0 _))\n")
)

Constraints ← (
  ⟜Vars
  ≡⌟(/$"_ _" ≡(□$"(* _ _)"))
  ≡(&w $"(assert (= (+ _) _))\n")
)

Presses ← (
  Joltages
  ⍜&runs (
    ⊸&w "(declare-const presses Int)\n"
    ⊸&w "(assert (<= 0 presses))\n"

    ◡(Declarations⊃(⋅⋅⋅∘|∘))
    ◡(Assertions⊃(⋅⋅⋅∘|∘))
    ◡(Constraints⊃(⋅⋅⋅⊙∘|∘))

    ⊸&w "(minimize presses)\n"
    ⊸&w "(check-sat)\n"
    ⊸&w "(get-value (presses))\n"
    &cl

    ⊙(&epf &rs ∞)

    &rs ∞
  ) {"z3" "-in"}
  ⊙⋅◌

  Lines
  °[□⊙□⊙]
  ⍤⤙≍ "sat"

  ⋕°$"((presses _))"
)

Part₁ ← /+ ≡Lights
Part₂ ← /+ ≡Presses

Part₁ Machines
Part₂ Machines
