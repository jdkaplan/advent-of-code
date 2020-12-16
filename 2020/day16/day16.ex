defmodule Day16 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    class: 0-1 or 4-19
    row: 0-5 or 8-19
    seat: 0-13 or 16-19

    your ticket:
    11,12,13

    nearby tickets:
    3,9,18
    15,1,5
    5,14,9
    """
  end

  defp parse_input(text) do
    [fields, mine, nearby] = String.split(text, "\n\n", trim: true)
    [_, my_ticket] = String.split(mine, "\n", trim: true)
    [_ | nearby_tickets] = String.split(nearby, "\n", trim: true)

    {
      parse_fields(fields),
      parse_ticket(my_ticket),
      Enum.map(nearby_tickets, &parse_ticket/1)
    }
  end

  @field_pattern ~r/^(?<name>.*): (?<range1_lo>\d+)-(?<range1_hi>\d+) or (?<range2_lo>\d+)-(?<range2_hi>\d+)$/

  defp parse_fields(text) do
    String.split(text, "\n")
    |> Enum.map(fn line ->
      %{
        "name" => name,
        "range1_lo" => range1_lo,
        "range1_hi" => range1_hi,
        "range2_lo" => range2_lo,
        "range2_hi" => range2_hi
      } = Regex.named_captures(@field_pattern, line)

      r1_lo = String.to_integer(range1_lo)
      r1_hi = String.to_integer(range1_hi)
      r2_lo = String.to_integer(range2_lo)
      r2_hi = String.to_integer(range2_hi)
      {name, r1_lo..r1_hi, r2_lo..r2_hi}
    end)
  end

  defp parse_ticket(line) do
    String.split(line, ",", trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  defp validate(fields, ticket) do
    Enum.reject(ticket, fn value ->
      Enum.any?(fields, &can_match?(&1, value))
    end)
    |> Enum.sum()
  end

  defp can_match?({_name, r1, r2}, value) do
    in_range?(r1, value) or in_range?(r2, value)
  end

  defp in_range?(lo..hi, val) do
    lo <= val and val <= hi
  end

  def part1 do
    {fields, _mine, nearby} = read_input() |> parse_input()

    Enum.map(nearby, &validate(fields, &1))
    |> Enum.sum()
  end

  def part2 do
    {fields, mine, nearby} = read_input() |> parse_input()

    Enum.filter(nearby, &(validate(fields, &1) == 0))
    |> columns(Enum.count(fields))
    |> deduce(fields)
    |> departure(mine)
  end

  defp departure(mapping, ticket) do
    Enum.reduce(mapping, 1, fn {name, idx}, product ->
      if String.starts_with?(name, "departure") do
        product * Enum.at(ticket, idx)
      else
        product
      end
    end)
  end

  defp columns(tickets, field_count) do
    Enum.reduce(tickets, List.duplicate([], field_count), fn ticket, columns ->
      Enum.zip(ticket, columns)
      |> Enum.map(fn {value, list} -> [value | list] end)
    end)
  end

  defp deduce(columns, fields) do
    possible =
      Enum.map(columns, fn values ->
        Enum.filter(fields, fn field ->
          Enum.all?(values, &can_match?(field, &1))
        end)
      end)

    constrain(%{}, Enum.with_index(possible))
  end

  defp constrain(known, []), do: known

  defp constrain(known, possible) do
    {solved, unsolved} =
      Enum.split_with(possible, fn {fields, _idx} ->
        Enum.count(fields) == 1
      end)

    solved_names = Enum.map(solved, fn {[{name, _r1, _r2}], _idx} -> name end) |> MapSet.new()

    new_possible =
      Enum.map(unsolved, fn {fields, idx} ->
        new_fields =
          Enum.reject(fields, fn {name, _, _} ->
            MapSet.member?(solved_names, name)
          end)

        {new_fields, idx}
      end)

    new_known = Enum.into(solved, known, fn {[{name, _r1, _r2}], idx} -> {name, idx} end)
    constrain(new_known, new_possible)
  end
end

Day16.part1() |> IO.inspect()
Day16.part2() |> IO.inspect()
