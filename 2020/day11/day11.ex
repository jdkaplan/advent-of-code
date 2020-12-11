defmodule Day11 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_layout(text) do
    String.split(text, "\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {line, r}, map ->
      String.codepoints(line)
      |> Enum.with_index()
      |> Enum.reduce(map, fn {char, c}, map ->
        Map.put(map, {r, c}, char_to_content(char))
      end)
    end)
  end

  defp char_to_content(char) do
    case char do
      "." -> :floor
      "L" -> :empty
      "#" -> :occupied
    end
  end

  defp content(grid, cell) do
    Map.get(grid, cell, :void)
  end

  defp neighbors(grid, {r, c}) do
    [
      {r - 1, c - 1},
      {r - 1, c},
      {r - 1, c + 1},
      {r, c - 1},
      {r, c + 1},
      {r + 1, c - 1},
      {r + 1, c},
      {r + 1, c + 1}
    ]
    |> Enum.map(&content(grid, &1))
  end

  defp tick(grid) do
    Enum.into(grid, %{}, fn {cell, state} ->
      new_state =
        case state do
          :floor ->
            :floor

          :empty ->
            if Enum.all?(neighbors(grid, cell), &(&1 != :occupied)) do
              :occupied
            else
              :empty
            end

          :occupied ->
            if Enum.count(neighbors(grid, cell), &(&1 == :occupied)) >= 4 do
              :empty
            else
              :occupied
            end
        end

      {cell, new_state}
    end)
  end

  defp run(grid) do
    new_grid = tick(grid)

    if new_grid == grid do
      grid
    else
      run(new_grid)
    end
  end

  defp count_seated(grid) do
    Map.values(grid) |> Enum.count(&(&1 == :occupied))
  end

  def part1 do
    read_input()
    |> parse_layout()
    |> run()
    |> count_seated()
  end

  defp tick2(grid, dims) do
    occupied = Enum.filter(grid, fn {_, state} -> state == :occupied end)

    neighbors =
      Enum.reduce(occupied, %{}, fn {cell, _}, counts ->
        visible_cells(grid, cell)
        |> Enum.reduce(counts, fn cell, counts ->
          count = Map.get(counts, cell, 0)
          Map.put(counts, cell, count + 1)
        end)
      end)

    # show_counts(neighbors, dims)

    Enum.into(grid, %{}, fn {cell, state} ->
      new_state =
        case state do
          :floor ->
            :floor

          :empty ->
            if Map.get(neighbors, cell, 0) == 0 do
              :occupied
            else
              :empty
            end

          :occupied ->
            if Map.get(neighbors, cell, 0) >= 5 do
              :empty
            else
              :occupied
            end
        end

      {cell, new_state}
    end)
  end

  defp visible_cells(grid, cell) do
    [
      {-1, -1},
      {-1, 0},
      {-1, +1},
      {0, -1},
      {0, +1},
      {+1, -1},
      {+1, 0},
      {+1, +1}
    ]
    |> Enum.flat_map(&ray_segment(grid, cell, &1))
  end

  defp ray_segment(grid, {rr, cc}, {dr, dc}) do
    # Skip current cell
    first = {rr + dr, cc + dc}

    Stream.iterate(first, fn {r, c} -> {r + dr, c + dc} end)
    |> Enum.reduce_while([], fn cell, cells ->
      case content(grid, cell) do
        :occupied -> {:halt, [cell | cells]}
        :empty -> {:halt, [cell | cells]}
        :floor -> {:cont, [cell | cells]}
        # nothing to see here
        :void -> {:halt, cells}
      end
    end)
  end

  defp run2(grid, dims = {h, w}) do
    # IO.puts("-------------------------")
    # show(grid, {h, w})

    new_grid = tick2(grid, dims)

    if new_grid == grid do
      grid
    else
      run2(new_grid, dims)
    end
  end

  defp show(grid, {h, w}) do
    for r <- 0..(h - 1) do
      for c <- 0..(w - 1) do
        IO.write(content_to_char(content(grid, {r, c})))
      end

      IO.write("\n")
    end
  end

  defp show_counts(grid, {h, w}) do
    for r <- 0..(h - 1) do
      for c <- 0..(w - 1) do
        IO.write(Map.get(grid, {r, c}, 0))
      end

      IO.write("\n")
    end
  end

  defp content_to_char(content) do
    case content do
      :floor -> "."
      :empty -> "L"
      :occupied -> "#"
    end
  end

  defp test_input do
    """
    L.LL.LL.LL
    LLLLLLL.LL
    L.L.L..L..
    LLLL.LL.LL
    L.LL.LL.LL
    L.LLLLL.LL
    ..L.L.....
    LLLLLLLLLL
    L.LLLLLL.L
    L.LLLLL.LL
    """
  end

  def part2 do
    grid = read_input() |> parse_layout()
    h = Enum.map(grid, fn {{r, _c}, _} -> r end) |> Enum.max()
    w = Enum.map(grid, fn {{_r, c}, _} -> c end) |> Enum.max()

    run2(grid, {h + 1, w + 1})
    |> count_seated()
  end

  def debug_state do
    """
    #.##.##.##
    #######.##
    #.#.#..#..
    ####.##.##
    #.##.##.##
    #.#####.##
    ..#.#.....
    ##########
    #.######.#
    #.#####.##
    """
  end

  def debug do
    grid = debug_state() |> parse_layout()
    show(grid, {10, 10})

    Map.keys(grid)
    |> Enum.filter(fn cell ->
      Enum.member?(visible_cells(grid, cell), {0, 6})
    end)
    |> Enum.into(%{}, fn cell -> {cell, content(grid, cell)} end)
    |> IO.inspect()

    tick(grid) |> show({10, 10})
  end
end

Day11.part1() |> IO.inspect()
Day11.part2() |> IO.inspect()
