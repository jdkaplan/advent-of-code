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
end

Day7.part1() |> IO.inspect()
