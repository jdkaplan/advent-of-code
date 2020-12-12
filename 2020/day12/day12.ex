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

  def part2 do
    read_input()
    |> parse_instructions()
    |> point({0, 0}, {10, 1})
    |> manhattan({0, 0})
  end

  defp point([], ferry, _waypoint) do
    ferry
  end

  defp point([instruction | rest], ferry, waypoint) do
    {new_ferry, new_waypoint} =
      case instruction do
        {:N, dy} -> {ferry, v_add(waypoint, {0, +dy})}
        {:S, dy} -> {ferry, v_add(waypoint, {0, -dy})}
        {:E, dx} -> {ferry, v_add(waypoint, {+dx, 0})}
        {:W, dx} -> {ferry, v_add(waypoint, {-dx, 0})}
        {:L, deg} -> {ferry, rotate(waypoint, deg)}
        {:R, deg} -> {ferry, rotate(waypoint, -deg)}
        {:F, dist} -> {move2(waypoint, ferry, dist), waypoint}
      end

    point(rest, new_ferry, new_waypoint)
  end

  defp move2({vx, vy}, {rx, ry}, d) do
    {rx + d * vx, ry + d * vy}
  end

  defp v_add({tx, ty}, {rx, ry}) do
    {tx + rx, ty + ry}
  end

  def c_mul({r1, i1}, {r2, i2}) do
    r = r1 * r2 - i1 * i2
    i = r1 * i2 + i1 * r2
    {r, i}
  end

  def c_pow(_z, 0), do: {1, 0}

  def c_pow(z, n) do
    Enum.reduce(Enum.into(1..n, [], fn _ -> z end), &c_mul/2)
  end

  defp rotate(vector, deg) do
    ticks = div(deg, 90)

    if ticks < 0 do
      c_mul(vector, c_pow({0, -1}, -ticks))
    else
      c_mul(vector, c_pow({0, 1}, ticks))
    end
  end

  def debug do
    IO.inspect({-56, 28})
    rotate({56, -28}, 180)
    rotate({56, -28}, -180)
  end
end

Day12.part1() |> IO.inspect()
Day12.part2() |> IO.inspect()
