defmodule Day4 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_passports(text) do
    String.split(text, "\n\n")
    |> Enum.map(fn block ->
      fields = String.split(block)

      Enum.reduce(fields, %{}, fn field, passport ->
        [key, val] = String.split(field, ":")
        Map.put(passport, key, val)
      end)
    end)
  end

  @required_fields [
    "byr",
    "iyr",
    "eyr",
    "hgt",
    "hcl",
    "ecl",
    "pid"
    # "cid"
  ]

  defp valid?(passport) do
    Enum.all?(@required_fields, fn field ->
      case Map.fetch(passport, field) do
        {:ok, _val} -> true
        :error -> false
      end
    end)
  end

  def part1 do
    read_input()
    |> parse_passports()
    |> Enum.count(&valid?/1)
  end
end

Day4.part1() |> IO.inspect()
