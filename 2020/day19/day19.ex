defmodule RBNF do
  def build_grammar(rules) do
    rules
    |> Enum.into(%{}, fn [name, rbnf] ->
      {
        name,
        {:alt,
         String.split(rbnf, " | ")
         |> Enum.map(fn text ->
           seq =
             String.split(text, " ")
             |> Enum.map(fn chars ->
               cond do
                 String.match?(chars, ~r/^\d+$/) -> {:ref, chars}
                 String.match?(chars, ~r/^".*"$/) -> {:lit, String.slice(chars, 1..-2)}
               end
             end)

           {:seq, seq}
         end)}
      }
    end)
  end

  # Returns {matched_text, remaining_text}
  def parse(grammar, rule, text) do
    case rule do
      {:lit, char} ->
        if String.at(text, 0) == char do
          String.split_at(text, 1)
        else
          {nil, text}
        end

      {:ref, name} ->
        parse(grammar, Map.fetch!(grammar, name), text)

      {:seq, rules} ->
        {matches, remaining} =
          Enum.map_reduce(rules, text, fn rule, buffer ->
            if buffer == nil do
              # An earlier match failed -> bail out
              {nil, nil}
            else
              case parse(grammar, rule, buffer) do
                {nil, extra} -> {nil, nil}
                {matched, rest} -> {matched, rest}
              end
            end
          end)

        if Enum.all?(matches) do
          {Enum.join(matches), remaining}
        else
          {nil, text}
        end

      {:alt, rules} ->
        res =
          Enum.reduce_while(rules, text, fn rule, _ ->
            case parse(grammar, rule, text) do
              {nil, _} -> {:cont, nil}
              {matched, rest} -> {:halt, {matched, rest}}
            end
          end)

        case res do
          # Nothing matched
          nil -> {nil, text}
          {matched, rest} -> {matched, rest}
        end
    end
  end
end

defmodule Day19 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    0: 4 1 5
    1: 2 3 | 3 2
    2: 4 4 | 5 5
    3: 4 5 | 5 4
    4: "a"
    5: "b"

    ababbb
    bababa
    abbbab
    aaabbb
    aaaabbb
    """
  end

  defp parse_input(text) do
    [rules, messages] = String.split(text, "\n\n", trim: true)
    {parse_rules(rules), parse_messages(messages)}
  end

  defp parse_rules(text) do
    String.split(text, "\n", trim: true)
    |> Enum.map(&String.split(&1, ": "))
  end

  defp parse_messages(text) do
    String.split(text, "\n", trim: true)
  end

  def part1 do
    {rules, messages} = read_input() |> parse_input()
    grammar = RBNF.build_grammar(rules)

    Enum.count(messages, fn msg ->
      case RBNF.parse(grammar, {:ref, "0"}, msg) do
        {msg, ""} -> true
        _ -> false
      end
    end)
  end
end

Day19.part1() |> IO.inspect()
