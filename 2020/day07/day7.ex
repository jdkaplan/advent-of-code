defmodule Day7 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_rules(text) do
    String.split(String.trim(text), "\n")
    |> Enum.map(&parse_rule/1)
    |> Enum.into(%{}, fn %{color: color, contents: contents} -> {color, contents} end)
  end

  @line_pattern ~r/^(?<color>.*?) bags contain (?<contents>.*?)\.$/
  @clause_pattern ~r/^(?<count>\d+) (?<color>.*?) bags?$/

  defp parse_rule(line) do
    match = Regex.named_captures(@line_pattern, line)

    %{
      color: Map.fetch!(match, "color"),
      contents: parse_contents(Map.fetch!(match, "contents"))
    }
  end

  defp parse_contents(text) do
    if text == "no other bags" do
      []
    else
      String.split(text, ", ")
      |> Enum.map(fn clause ->
        match = Regex.named_captures(@clause_pattern, clause)
        count = String.to_integer(Map.fetch!(match, "count"))
        color = Map.fetch!(match, "color")
        %{count: count, color: color}
      end)
    end
  end

  defp contain_fixpoint(rules, targets) do
    new_targets =
      Enum.reduce(rules, targets, fn {outer, inners}, working_set ->
        inner_set = MapSet.new(Enum.map(inners, fn %{color: color} -> color end))

        if MapSet.size(MapSet.intersection(targets, inner_set)) > 0 do
          MapSet.put(working_set, outer)
        else
          working_set
        end
      end)

    if targets == new_targets do
      new_targets
    else
      contain_fixpoint(rules, new_targets)
    end
  end

  def part1 do
    rules = parse_rules(read_input())
    containing_colors = contain_fixpoint(rules, MapSet.new(["shiny gold"]))
    # No recursion :sweat_smile:
    MapSet.size(MapSet.delete(containing_colors, "shiny gold"))
  end

  def part2 do
    rules = parse_rules(read_input())
    counts = solve_fixpoint(rules, %{})
    # Exclude outermost
    counts["shiny gold"] - 1
  end

  defp solve_fixpoint(todo, counts) do
    if Enum.empty?(todo) do
      counts
    else
      {color, _contents} =
        Enum.find(todo, nil, fn {color, _contents} -> solvable?(todo, counts, color) end)

      {new_todo, new_counts} = solve(todo, counts, color)
      solve_fixpoint(new_todo, new_counts)
    end
  end

  defp solved?(counts, color) do
    Map.has_key?(counts, color)
  end

  defp solvable?(todo, counts, color) do
    solved?(counts, color) or
      Enum.all?(todo[color], fn %{color: inner} -> solved?(counts, inner) end)
  end

  defp inner_count(todo, counts, color) do
    Enum.reduce(todo[color], 0, fn %{count: count, color: inner}, sum ->
      sum + count * counts[inner]
    end)
  end

  defp solve(todo, counts, color) do
    {Map.delete(todo, color), Map.put(counts, color, 1 + inner_count(todo, counts, color))}
  end
end

Day7.part1() |> IO.inspect()
Day7.part2() |> IO.inspect()
