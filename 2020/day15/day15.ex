defmodule Day15 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    0,3,6
    """
  end

  defp parse_numbers(text) do
    text
    |> String.trim()
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  defp next([previous | rest]) do
    {_, idx} =
      rest
      |> Enum.with_index()
      |> Enum.find({previous, -1}, fn {num, _idx} -> num == previous end)

    idx + 1
  end

  defp run(log, limit) do
    if Enum.count(log) == limit do
      Enum.at(log, 0)
    else
      run([next(log) | log], limit)
    end
  end

  def part1(limit) do
    read_input()
    |> parse_numbers()
    |> Enum.reverse()
    |> run(limit)
  end

  defp setup(initial) do
    cache =
      initial
      |> Enum.slice(0..-2)
      |> Enum.with_index()
      |> Enum.into(%{})

    {cache, Enum.at(initial, -1)}
  end

  defp next2(cache, said, now) do
    now - Map.get(cache, said, now)
  end

  defp run2(cache, said, now, stop) do
    say = next2(cache, said, now)

    if now + 1 == stop do
      said
    else
      run2(Map.put(cache, said, now), say, now + 1, stop)
    end
  end

  def part2(limit) do
    {cache, said} =
      read_input()
      |> parse_numbers()
      |> setup()

    run2(cache, said, map_size(cache), limit)
  end

  def debug(limit) do
    10..limit
    |> Enum.filter(fn i ->
      p1 = part1(i)
      p2 = part2(i)
      p1 != p2
    end)
  end
end

Day15.part1(2020) |> IO.inspect()
Day15.part2(30_000_000) |> IO.inspect()
