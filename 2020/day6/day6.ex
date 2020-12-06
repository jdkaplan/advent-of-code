defmodule Day6 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  def part1 do
    read_input()
    |> String.split("\n\n")
    |> Enum.map(fn block ->
      String.split(block)
      |> Enum.reduce(MapSet.new(), fn line, set ->
        MapSet.union(set, MapSet.new(String.codepoints(line)))
      end)
    end)
    |> Enum.map(&MapSet.size/1)
    |> Enum.sum()
  end
end

Day6.part1() |> IO.inspect()
