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

  defp valid_sled?(policy, password) do
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

  defp valid_toboggan?(policy, password) do
    chars = String.codepoints(password)
    l1 = Enum.at(chars, policy.min - 1)
    l2 = Enum.at(chars, policy.max - 1)
    (l1 == policy.letter or l2 == policy.letter) and l1 != l2
  end

  defp xor(a, b) do
    (a or b) and a != b
  end

  def part1 do
    parse(read_input())
    |> Enum.filter(fn %{policy: policy, password: password} -> valid_sled?(policy, password) end)
    |> length()
  end

  def part2 do
    parse(read_input())
    |> Enum.filter(fn %{policy: policy, password: password} ->
      valid_toboggan?(policy, password)
    end)
    |> length()
  end
end

Day2.part1() |> IO.inspect()
Day2.part2() |> IO.inspect()
