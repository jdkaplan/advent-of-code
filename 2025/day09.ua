~ "aoc.ua" ~ Lines

Lines &fras "input/day09.txt"
≡◇(⊜⋕ ⊸≠@,)
Tiles ←

Area ← /×+1⌵-°⊟

Part₁ ← (
  ⊏ ⧅₂< °⊏
  /↥≡Area
)

# In ? Point Segment
InSegment ← (
  ⊙°⊟
  /↧×⊓⌞≤≥
)

# On ? Point Polygon
OnPath ← /↥ ≡⌞InSegment

# dW ? Point Segment
Crossings ← (
  ◡⋅(=∩⊢ °⊟) # Axis Point Segment ? Point Segment
  ⨬(⋅⋅0|(
      ◡(> ∩⊢ ⊙⊢) # Consider Point Segment ? Point Segment
      ⨬(⋅⋅0|(
          ◡⋅(< ∩⊣ °⊟)      # Backwards Point Segment ? Point Segment
          ⨬(1|¯1 ⊙⇌)       # Sign Point Segment ? Backwards Point Segment
          ◡⋅(/↥ ≡⌞= ⊣ ⊙≡⊣) # Edge Sign Point Segment ? Sign Point Segment
          ⨬(⊙(
              ⊣⊙(°⊟≡⊣)
              /↧×⊓⌞<>
            )
          | 0.5⊙⋅⋅
          )
          ×
        ))
    ))
)

# W ? Point Polygon
Winding ← (
  /+ ≡⌞Crossings
)

# Inside ? Point Polygon
Inside ← (
  ◡OnPath
  ⨬(≠₀ Winding|1)
)

Det₂ ← (
  ⊃(⊡0_1|⊡1_0|⊡0_0|⊡1_1)
  -⊓××
)

# v1 v2 v3 v4
U ← (
  ⊃(˜-⊙⋅∘|˜-⋅⋅⊙∘)
  ⊟
  ¯Det₂
)

# v1 v2 v3 v4
T ← (
  ⊃(˜-⊙∘|˜-⊙⋅∘|⋅⋅⋅⋅)
  ⊟
  Det₂
)

# v1 v2 v3 v4
D ← (
  ⊃(˜-⊙∘|˜-⋅⋅⊙∘)
  ˜⊟
  Det₂
)

# Intersects ? Side Segment
Intersects ← (
  ∩°⊟
  ⊃(D|T|U)
  ⊸=0
  ⨬(∩⌞(×⊃>₀<₁ ÷)
    ×
  | ⋅⋅⋅0
  )
)

# Safe ? Side Polygon
Safe ← ¬/↥ ≡⌞Intersects

# Contained ? Corners Polygon
Contained ← (
  # The actual corners are on the polygon by definition.
  # Get the other two for a quick test...
  ⊂⊸(⍜⍉ ⍜°⊟ ⊙↻₁)
  ◡(/↧ ≡⌟Inside)
  ⨬(⋅⋅0|(
      # ... but test the full sides if we really have to.
      ⊏ [0_2 2_1 1_3 3_0]
      /↧ ≡⌟Safe
    ))
)

Part₂ ← (
  ⟜((≡⊟)⤙↻1)
  ⊏ ⧅₂< °⊏
  ⊏⍖⊸≡Area
  ⍢(↘1|¬Contained⊢)
  ⊙◌
  ⊢
  Area
)

Part₁ Tiles
Part₂ Tiles
