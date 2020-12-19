defmodule RBNF do
  def build_grammar(rules) do
    rules
    |> Enum.into(%{}, fn [name, rbnf] ->
      {
        name,
        make_rule(rbnf)
      }
    end)
  end

  def make_rule(str) do
    {:alt,
     String.split(str, " | ")
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
                {nil, _} -> {nil, nil}
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

      {:plus, repeated} ->
        case parse(grammar, repeated, text) do
          {nil, _} -> {nil, text}
          {matched, rest} -> star_iter(grammar, repeated, matched, rest)
        end

      {:paired, r1, r2} ->
        {count, prefix, rest} = count_iter(grammar, r1, "", 0, text)

        if count == 0 do
          {nil, text}
        else
          new_rule = {:seq, List.duplicate(r2, count)}

          case parse(grammar, new_rule, rest) do
            {nil, _} -> {nil, text}
            {suffix, remaining} -> {prefix <> suffix, remaining}
          end
        end

      {:left_sided, left, right} ->
        {count, prefix, rest} = count_iter(grammar, left, "", 0, text)

        if count < 2 do
          # No extra lefts to match with
          {nil, text}
        else
          new_rule = {:at_most, right, count - 1}

          case parse(grammar, new_rule, rest) do
            {nil, _} -> {nil, text}
            {suffix, remaining} -> {prefix <> suffix, remaining}
          end
        end

      {:at_most, r, count} ->
        new_rule = {:alt, Enum.map(count..1, &{:seq, List.duplicate(r, &1)})}
        parse(grammar, new_rule, text)
    end
  end

  defp star_iter(grammar, rule, prefix, text) do
    case parse(grammar, rule, text) do
      {nil, _} -> {prefix, text}
      {matched, rest} -> star_iter(grammar, rule, prefix <> matched, rest)
    end
  end

  defp count_iter(grammar, rule, prefix, count, text) do
    case parse(grammar, rule, text) do
      {nil, _} -> {count, prefix, text}
      {matched, rest} -> count_iter(grammar, rule, prefix <> matched, count + 1, rest)
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
    42: 9 14 | 10 1
    9: 14 27 | 1 26
    10: 23 14 | 28 1
    1: "a"
    11: 42 31
    5: 1 14 | 15 1
    19: 14 1 | 14 14
    12: 24 14 | 19 1
    16: 15 1 | 14 14
    31: 14 17 | 1 13
    6: 14 14 | 1 14
    2: 1 24 | 14 4
    0: 8 11
    13: 14 3 | 1 12
    15: 1 | 14
    17: 14 2 | 1 7
    23: 25 1 | 22 14
    28: 16 1
    4: 1 1
    20: 14 14 | 1 15
    3: 5 14 | 16 1
    27: 1 6 | 14 18
    14: "b"
    21: 14 1 | 1 14
    25: 1 1 | 1 14
    22: 14 14
    8: 42
    26: 14 22 | 1 20
    18: 15 15
    7: 14 5 | 1 21
    24: 14 1

    abbbbbabbbaaaababbaabbbbabababbbabbbbbbabaaaa
    bbabbbbaabaabba
    babbbbaabbbbbabbbbbbaabaaabaaa
    aaabbbbbbaaaabaababaabababbabaaabbababababaaa
    bbbbbbbaaaabbbbaaabbabaaa
    bbbababbbbaaaaaaaabbababaaababaabab
    ababaaaaaabaaab
    ababaaaaabbbaba
    baabbaaaabbaaaababbaababb
    abbbbabbbbaaaababbbbbbaaaababb
    aaaaabbaabaaaaababaa
    aaaabbaaaabbaaa
    aaaabbaabbaaaaaaabbbabbbaaabbaabaaa
    babaaabbbaaabaababbaabababaaab
    aabbbbbaabbbaaaaaabbbbbababaaaaabbaaabba
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
        {_, ""} -> true
        _ -> false
      end
    end)
  end

  def part2 do
    {rules, messages} = read_input() |> parse_input()

    grammar =
      RBNF.build_grammar(rules)
      # 8: 42 | 42 8 = 42+
      |> Map.put("8", {:plus, {:ref, "42"}})
      # 11: 42 31 | 42 11 31 = same number of 42 and 31 (at least one pair)
      |> Map.put(
        "11",
        {:paired, {:ref, "42"}, {:ref, "31"}}
      )
      # 0: 8 11 = 42+ (matched 42 31) = 42 42{N} 31{1,N-1} = 42{M} 31{1,M-1}
      |> Map.put(
        "0",
        {:left_sided, {:ref, "42"}, {:ref, "31"}}
      )

    Enum.count(messages, fn msg ->
      case RBNF.parse(grammar, {:ref, "0"}, msg) do
        {_, ""} -> true
        _ -> false
      end
    end)
  end
end

Day19.part1() |> IO.inspect()
Day19.part2() |> IO.inspect()
