defmodule SetTools do
  def combinations(_, 0) do
    [[]]
  end

  def combinations([], _) do
    []
  end

  def combinations(list = [head | tail], size) do
    taken = Stream.map(combinations(tail, size - 1), fn subset -> [head | subset] end)
    left = combinations(tail, size)
    Stream.concat(taken, left)
  end
end

defmodule Day9 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_lines(text) do
    text
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.to_integer/1)
  end

  def part1 do
    preamble_size = 25

    read_input()
    |> parse_lines()
    |> Stream.chunk_every(preamble_size + 1, 1, :discard)
    |> Enum.find(fn numbers ->
      preamble = Enum.take(numbers, preamble_size)
      next = List.last(numbers)

      has_match =
        SetTools.combinations(preamble, 2)
        |> Enum.any?(fn subset -> next == Enum.sum(subset) end)

      !has_match
    end)
    |> Enum.at(preamble_size)
  end
end

Day9.part1() |> IO.inspect()
