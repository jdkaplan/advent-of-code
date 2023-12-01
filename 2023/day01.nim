const numbers = "0123456789"
const words = @[
  "one",
  "two",
  "three",
  "four",
  "five",
  "six",
  "seven",
  "eight",
  "nine",
]

proc part1(): int =
  let f = open("input/day01.txt")
  defer: f.close()

  var line: string
  while f.readLine(line):
    var nums: seq[int] = @[]
    for char in line:
      if char in numbers:
        nums.add(char.int - '0'.int)

    result += 10 * nums[0] + nums[^1]

proc extractNumsOverlap(line: string): seq[int] =
  var i = 0
  while i < line.len:
    let char = line[i]

    if char in numbers:
      result.add(char.int - '0'.int)
      inc i
      continue

    for n, word in words:
      let
        size = word.len
        cap = min(i + size, line.len)
      if line[i..<cap] == word:
        result.add(n+1)
        break
    inc i

proc part2(): int =
  let f = open("input/day01.txt")
  defer: f.close()

  var line: string
  while f.readLine(line):
    let
      nums = extractNumsOverlap(line)

    result += 10 * nums[0] + nums[^1]

echo part1()
echo part2()
