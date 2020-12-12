defmodule Day12 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_instructions(text) do
    String.split(text, "\n", trim: true)
    |> Enum.map(fn line ->
      {
        String.first(line) |> String.to_atom(),
        String.slice(line, 1..-1) |> String.to_integer()
      }
    end)
  end

  defp steer([], _heading, position) do
    position
  end

  defp steer([instruction | rest], heading, position = {x, y}) do
    {new_heading, new_position} =
      case instruction do
        {:N, dy} -> {heading, {x, y + dy}}
        {:S, dy} -> {heading, {x, y - dy}}
        {:E, dx} -> {heading, {x + dx, y}}
        {:W, dx} -> {heading, {x - dx, y}}
        {:L, deg} -> {turn(heading, deg), position}
        {:R, deg} -> {turn(heading, -deg), position}
        {:F, dist} -> {heading, move(heading, position, dist)}
      end

    steer(rest, new_heading, new_position)
  end

  defp turn(heading, degrees) do
    hd = %{E: 0, N: 90, W: 180, S: 270}
    dh = Enum.into(hd, %{}, fn {h, d} -> {d, h} end)

    new_deg = Map.fetch!(hd, heading) + degrees
    Map.fetch!(dh, rem(new_deg + 360, 360))
  end

  defp move(heading, {x, y}, distance) do
    case heading do
      :N -> {x, y + distance}
      :S -> {x, y - distance}
      :E -> {x + distance, y}
      :W -> {x - distance, y}
    end
  end

  defp manhattan({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp test_input do
    """
    F10
    N3
    F7
    R90
    F11
    """
  end

  def part1 do
    read_input()
    |> parse_instructions()
    |> steer(:E, {0, 0})
    |> manhattan({0, 0})
  end

  def debug do
    for h <- [:N, :S, :E, :W],
        d <- [0, 90, 180, 270, 360, -90, -180, -270] do
      turn(h, d)
    end
  end
end

Day12.part1() |> IO.inspect()
# Day12.debug() |> IO.inspect()
