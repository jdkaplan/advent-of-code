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
    Map.get(grid, cell, :floor)
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
end

Day11.part1() |> IO.inspect()
