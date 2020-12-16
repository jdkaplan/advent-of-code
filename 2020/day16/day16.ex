defmodule Day16 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    class: 1-3 or 5-7
    row: 6-11 or 33-44
    seat: 13-40 or 45-50

    your ticket:
    7,1,14

    nearby tickets:
    7,3,47
    40,4,50
    55,2,20
    38,6,12
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
end

Day16.part1() |> IO.inspect()
