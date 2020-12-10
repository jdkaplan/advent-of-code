defmodule Day10 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_adapters(text) do
    joltages = text |> String.trim() |> String.split("\n") |> Enum.map(&String.to_integer/1)
    joltages ++ [3 + Enum.max(joltages)]
  end

  defp super_power(adapters, stack = [top | _rest]) do
    as = Enum.filter(adapters, fn next -> can_stack?(top, next) end)

    if Enum.empty?(as) do
      stack
    else
      next = Enum.min(as)
      remaining = Enum.reject(adapters, fn a -> a == next end)
      super_power(remaining, [next | stack])
    end
  end

  defp can_stack?(a1, a2) do
    d = a2 - a1
    1 <= d and d <= 3
  end

  defp pairs(enum) do
    Enum.chunk_every(enum, 2, 1, :discard)
  end

  def part1 do
    adapters = read_input() |> parse_adapters()

    counts =
      super_power(adapters, [0])
      |> pairs()
      |> Enum.reduce(%{}, fn [a2, a1], counts ->
        d = a2 - a1
        Map.put(counts, d, Map.get(counts, d, 0) + 1)
      end)

    counts[3] * counts[1]
  end
end

Day10.part1() |> IO.inspect()
