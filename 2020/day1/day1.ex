defmodule Day1 do
  def all_pairs(list) do
    Enum.reduce(0..(length(list) - 1), [], fn idx, pairs ->
      item = Enum.at(list, idx)
      other_items = Enum.slice(list, (idx + 1)..(length(list) - 1))
      new_pairs = Enum.map(other_items, fn elt -> {item, elt} end)
      pairs ++ new_pairs
    end)
  end

  def part1(input) do
    lines = String.split(input)
    ints = Enum.map(lines, fn line -> String.to_integer(line) end)
    pairs = Day1.all_pairs(ints)
    [{a, b}] = Enum.filter(pairs, fn {a, b} -> a + b == 2020 end)
    a * b
  end
end

input = File.read!("input.txt")
IO.inspect(Day1.part1(input))
