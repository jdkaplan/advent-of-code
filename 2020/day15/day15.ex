defmodule Day15 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    0,3,6
    """
  end

  defp parse_numbers(text) do
    text
    |> String.trim()
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  defp next([previous | rest]) do
    {_, idx} =
      rest
      |> Enum.with_index()
      |> Enum.find({previous, -1}, fn {num, idx} -> num == previous end)

    idx + 1
  end

  defp run(log, limit) do
    if Enum.count(log) == limit do
      Enum.at(log, 0)
    else
      run([next(log) | log], limit)
    end
  end

  def part1 do
    read_input()
    |> parse_numbers()
    |> Enum.reverse()
    |> run(2020)
  end
end

Day15.part1() |> IO.inspect()
