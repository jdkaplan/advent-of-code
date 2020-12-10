defmodule Day5 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp half_range({lo, hi}, half) do
    halfway = lo + div(hi + 1 - lo, 2)
    lower = {lo, halfway - 1}
    upper = {halfway, hi}

    case half do
      :lower -> lower
      :upper -> upper
    end
  end

  defp parse_seat(line) do
    %{row: {r, r}, col: {c, c}} =
      String.codepoints(line)
      |> Enum.reduce(%{row: {0, 127}, col: {0, 7}}, fn char, %{row: row, col: col} ->
        case char do
          "F" -> %{row: half_range(row, :lower), col: col}
          "B" -> %{row: half_range(row, :upper), col: col}
          "L" -> %{row: row, col: half_range(col, :lower)}
          "R" -> %{row: row, col: half_range(col, :upper)}
        end
      end)

    {r, c}
  end

  defp seat_id({r, c}) do
    r * 8 + c
  end

  def part1 do
    read_input()
    |> String.split()
    |> Enum.map(&parse_seat/1)
    |> Enum.map(&seat_id/1)
    |> Enum.max()
  end

  defp find_hole(seat_ids) do
    [{lo, hi}] =
      Enum.zip(
        Enum.slice(seat_ids, 0..-2),
        Enum.slice(seat_ids, 1..-1)
      )
      |> Enum.filter(fn {a, b} -> b - a != 1 end)

    lo + 1
  end

  def part2 do
    read_input()
    |> String.split()
    |> Enum.map(&parse_seat/1)
    |> Enum.map(&seat_id/1)
    |> Enum.sort()
    |> find_hole
  end
end

Day5.part1() |> IO.inspect()
Day5.part2() |> IO.inspect()
