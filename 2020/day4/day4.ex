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

  defp all_fields?(passport) do
    Enum.all?(@required_fields, fn field ->
      case Map.fetch(passport, field) do
        {:ok, _val} -> true
        :error -> false
      end
    end)
  end

  defp parse_int(val, default) do
    try do
      String.to_integer(val)
    rescue
      ArgumentError -> default
    end
  end

  defp valid?(passport) do
    validators = %{
      "byr" => fn val ->
        int = parse_int(val, 0)
        1920 <= int && int <= 2002
      end,
      "iyr" => fn val ->
        int = parse_int(val, 0)
        2010 <= int && int <= 2020
      end,
      "eyr" => fn val ->
        int = parse_int(val, 0)
        2020 <= int && int <= 2030
      end,
      "hgt" => fn val ->
        case Regex.named_captures(~r/^(?<num>\d+)(?<units>cm|in)$/, val) do
          %{"num" => num, "units" => units} ->
            int = parse_int(num, 0)

            case units do
              "cm" ->
                150 <= int && int <= 193

              "in" ->
                59 <= int && int <= 76
            end

          _ ->
            false
        end
      end,
      "hcl" => fn val -> Regex.match?(~r/^#[0-9a-f]{6}$/, val) end,
      "ecl" => fn val -> Enum.member?(["amb", "blu", "brn", "gry", "grn", "hzl", "oth"], val) end,
      "pid" => fn val -> Regex.match?(~r/^[0-9]{9}$/, val) end
      # cid
    }

    Map.to_list(validators)
    |> Enum.all?(fn {field, validator} ->
      case Map.get(passport, field) do
        nil -> false
        val -> validator.(val)
      end
    end)
  end

  def part1 do
    read_input()
    |> parse_passports()
    |> Enum.count(&all_fields?/1)
  end

  def part2 do
    read_input()
    |> parse_passports()
    |> Enum.count(&valid?/1)
  end
end

Day4.part1() |> IO.inspect()
Day4.part2() |> IO.inspect()
