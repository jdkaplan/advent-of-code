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
Log       ← ⌝˜ⁿ
NumDigits ← +1 ⌊ Log10
RepeatDigits ← (
  ⊸(˜ⁿ10 ÷2NumDigits)
  =⊃(⌊÷|◿)
)
ValidId ← (
  ⊸(◿2 NumDigits)
  ⨬(¬RepeatDigits|1)
)

⍚ParseRange Input
≡(
  ♭Seq°⊂°□
  ▽¬ ⊸ValidId
  /+
)
/+
