defmodule TreeMap do
  def start_link(map_text) do
    Task.start_link(fn -> loop(parse(map_text)) end)
  end

  defp parse(text) do
    String.split(text, "\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(%{grid: %{}, width: 0, height: 0}, fn {line, r}, map ->
      String.codepoints(line)
      |> Enum.with_index()
      |> Enum.reduce(map, fn {char, c}, map ->
        %{
          grid: Map.put(map.grid, {r, c}, char_to_content(char)),
          width: max(map.width, c + 1),
          height: max(map.height, r + 1)
        }
      end)
    end)
  end

  defp loop(map) do
    receive do
      {:get, {r, c}, caller} ->
        send(caller, Map.fetch(map.grid, wrap({r, c}, {map.width, map.height})))
        loop(map)
    end
  end

  defp wrap({r, c}, {w, _h}) do
    {r, rem(c, w)}
  end

  defp char_to_content(char) do
    case char do
      "." -> :open
      "#" -> :tree
    end
  end
end

defmodule Day2 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp content(tree_map, {r, c}) do
    send(tree_map, {:get, {r, c}, self()})

    receive do
      {:ok, content} -> content
      :error -> :error
    end
  end

  def part1 do
    {:ok, tree_map} = TreeMap.start_link(read_input)

    Stream.iterate({0, 0}, fn {r, c} -> {r + 1, c + 3} end)
    |> Enum.reduce_while(0, fn cell, tree_count ->
      case content(tree_map, cell) do
        :error -> {:halt, tree_count}
        :open -> {:cont, tree_count}
        :tree -> {:cont, tree_count + 1}
      end
    end)
  end
end

Day2.part1() |> IO.inspect()
