defmodule Day1 do
  def part1(input) do
    lines = String.split(input)
    ints = Enum.map(lines, fn line -> String.to_integer(line) end)
    pairs = all_pairs(ints)
    [{a, b}] = Enum.filter(pairs, fn {a, b} -> a + b == 2020 end)
    a * b
  end

  defp all_pairs(list) do
    Enum.reduce(0..(length(list) - 1), [], fn idx, pairs ->
      item = Enum.at(list, idx)
      other_items = Enum.slice(list, (idx + 1)..(length(list) - 1))
      new_pairs = Enum.map(other_items, fn elt -> {item, elt} end)
      pairs ++ new_pairs
    end)
  end

  # Wow, I'm out of shape when it comes to making sets recursively!

  def part2(input) do
    lines = String.split(input)
    ints = Enum.map(lines, &String.to_integer/1)
    pairs = all_triples(ints)
    [{a, b, c}] = Enum.filter(pairs, fn {a, b, c} -> a + b + c == 2020 end)
    a * b * c
  end

  defp all_triples(list) do
    Enum.reduce(0..(length(list) - 1), [], fn idx, triples ->
      item = Enum.at(list, idx)
      pairs = all_pairs(Enum.slice(list, (idx + 1)..(length(list) - 1)))
      new_triples = Enum.map(pairs, fn {a, b} -> {item, a, b} end)
      triples ++ new_triples
    end)
  end

  defp combinations(list, size) do
    indices = 0..(length(list) - 1)

    Enum.zip(for _ <- 1..size, do: indices)
    |> IO.inspect()
    |> Enum.filter(fn idxs -> length(Enum.uniq(Tuple.to_list(idxs))) == size end)
    |> Enum.map(fn idxs ->
      for i <- 0..(size - 1) do
        elem(idxs, i)
      end
    end)
  end
end

input = File.read!("input.txt")
IO.inspect(Day1.part1(input))
IO.inspect(Day1.part2(input))
