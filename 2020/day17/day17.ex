defmodule Day17 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    .#.
    ..#
    ###
    """
  end

  defp parse_space(text) do
    String.split(text, "\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {line, y}, map ->
      String.codepoints(line)
      |> Enum.with_index()
      |> Enum.reduce(map, fn {char, x}, map ->
        Map.put(map, {x, y, 0}, char_to_content(char))
      end)
    end)
  end

  defp char_to_content(char) do
    case char do
      "." -> :inactive
      "#" -> :active
    end
  end

  defp state_char(char) do
    case char do
      :inactive -> "."
      :active -> "#"
    end
  end

  defp expand_range(lo..hi, val) do
    cond do
      val < lo -> val..hi
      val > hi -> lo..val
      true -> lo..hi
    end
  end

  defp get_bounds(space) do
    Enum.reduce(space, %{x: 0..0, y: 0..0, z: 0..0}, fn {{x, y, z}, state}, bounds ->
      case state do
        :inactive ->
          bounds

        :active ->
          %{
            x: expand_range(bounds.x, x),
            y: expand_range(bounds.y, y),
            z: expand_range(bounds.z, z)
          }
      end
    end)
  end

  defp show(space) do
    bounds = get_bounds(space)

    for z <- bounds.z do
      IO.puts("z = #{z}")

      for y <- bounds.y do
        for x <- bounds.x do
          state = Map.get(space, {x, y, z}, :inactive)
          IO.write(state_char(state))
        end

        IO.write("\n")
      end

      IO.write("\n\n")
    end

    space
  end

  defp populate(space) do
    Enum.reduce(space, %{}, fn {cell, state}, counts ->
      if state == :inactive do
        counts
      else
        neighbors(cell)
        |> Enum.reduce(counts, fn neighbor, counts ->
          Map.put(counts, neighbor, 1 + Map.get(counts, neighbor, 0))
        end)
      end
    end)
  end

  defp tick(space) do
    populate(space)
    |> Enum.reduce(%{}, fn {cell, count}, new_space ->
      new_state =
        case Map.get(space, cell, :inactive) do
          :active ->
            if count == 2 or count == 3 do
              :active
            else
              :inactive
            end

          :inactive ->
            if count == 3 do
              :active
            else
              :inactive
            end
        end

      case new_state do
        :active -> Map.put(new_space, cell, :active)
        :inactive -> new_space
      end
    end)
  end

  defp neighbors(cell = {x, y, z}) do
    for dx <- -1..1,
        dy <- -1..1,
        dz <- -1..1 do
      {x + dx, y + dy, z + dz}
    end
    |> Enum.reject(&(&1 == cell))
  end

  defp run(space, 0) do
    space
  end

  defp run(space, cycles) do
    IO.puts("cycles = #{cycles}")
    show(space)

    tick(space)
    |> run(cycles - 1)
  end

  def part1 do
    read_input()
    |> parse_space()
    |> run(6)
    |> show()
    |> Enum.count(fn {_cell, state} -> state == :active end)
  end

  def debug do
    test_input()
    |> parse_space()
    |> tick()

    # neighbors(%{}, {0, 0, 0})
  end
end

Day17.part1() |> IO.inspect()
# Day17.debug() |> IO.inspect()
