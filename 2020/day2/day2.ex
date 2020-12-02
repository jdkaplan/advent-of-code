defmodule Day2 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse(input) do
    re = ~r/^(?<min>\d+)-(?<max>\d+) (?<letter>[a-z]): (?<password>[a-z]+)$/

    String.split(input, "\n", trim: true)
    |> Enum.map(fn line ->
      match = Regex.named_captures(re, line)

      %{
        policy: %{
          min: String.to_integer(Map.fetch!(match, "min")),
          max: String.to_integer(Map.fetch!(match, "max")),
          letter: Map.fetch!(match, "letter")
        },
        password: Map.fetch!(match, "password")
      }
    end)
  end

  defp valid?(policy, password) do
    count =
      Enum.reduce(String.codepoints(password), 0, fn char, count ->
        if char == policy.letter do
          count + 1
        else
          count
        end
      end)

    policy.min <= count and count <= policy.max
  end

  def part1 do
    parse(read_input())
    |> Enum.filter(fn %{policy: policy, password: password} -> valid?(policy, password) end)
    |> length()
    |> IO.inspect()
  end
end

Day2.part1()
