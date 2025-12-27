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

Machines
/+ ≡Lights
