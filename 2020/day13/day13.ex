defmodule Day13 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    _
    1789,37,47,1889
    """
  end

  defp parse_int(val, default) do
    try do
      String.to_integer(val)
    rescue
      ArgumentError -> default
    end
  end

  defp parse_schedule(text) do
    [line_1, line_2] = String.split(text, "\n", trim: true)
    timestamp = String.to_integer(line_1)

    bus_ids =
      String.split(line_2, ",")
      |> Enum.map(&parse_int(&1, nil))
      |> Enum.filter(& &1)

    {timestamp, bus_ids}
  end

  defp first_multiple_after(timestamp, bus_id) do
    if rem(timestamp, bus_id) == 0 do
      timestamp
    else
      bus_id * (div(timestamp, bus_id) + 1)
    end
  end

  def part1 do
    {timestamp, bus_ids} = read_input() |> parse_schedule()

    {bus_id, time} =
      Enum.map(bus_ids, &{&1, first_multiple_after(timestamp, &1)})
      |> Enum.min_by(fn {_, time} -> time end)

    bus_id * (time - timestamp)
  end

  defp parse_requirements(text) do
    [_, line_2] = String.split(text, "\n", trim: true)

    String.split(line_2, ",")
    |> Enum.map(&parse_int(&1, nil))
    |> Enum.with_index()
    |> Enum.filter(fn {offset, _} -> offset end)
  end

  def part2 do
    {_period, timestamp} =
      read_input()
      |> parse_requirements()
      |> Enum.map(fn {period, offset} -> {period, -offset} end)
      |> Enum.reduce(fn {n1, a1}, {n2, a2} ->
        unless coprime?(n1, n2) do
          raise :wat
        end

        x = chinese_remainder_theorem(a1, n1, a2, n2)
        n = n1 * n2
        {n, normalize_residue(rem(x, n), n)}
      end)

    timestamp
  end

  defp divmod(dividend, divisor) do
    {div(dividend, divisor), rem(dividend, divisor)}
  end

  def gcd(a, b) do
    {d, _, _, _, _} = extended_euclidean_division(a, b)
    d
  end

  # Returns {r, m1, d1, m2, d2} where the following properties hold:
  # 1. r == gcd(r1, r2)
  # 2. d1 == abs(r1 / r)
  # 3. d2 == abs(r2 / r)
  # 4. r1 * m1 + r2 * m2 == r
  def extended_euclidean_division(r1, r2) do
    extended_euclidean_division(r1, r2, 1, 0, 0, 1)
  end

  def extended_euclidean_division(r1, r2, s1, s2, t1, t2) do
    if r2 == 0 do
      {r1, s1, abs(t2), t1, abs(s2)}
    else
      {q, r} = divmod(r1, r2)
      s = s1 - q * s2
      t = t1 - q * t2
      extended_euclidean_division(r2, r, s2, s, t2, t)
    end
  end

  # m1 * n2 + m2 * n2 = 1
  def bezout_coefficients(n1, n2) do
    {_, m1, _, m2, _} = extended_euclidean_division(n1, n2)
    {m1, m2}
  end

  # Gives the solution to the following equations:
  # 1. x = a1 (mod n1)
  # 2. x = a2 (mod n2)
  def chinese_remainder_theorem(a1, n1, a2, n2) do
    {m1, m2} = bezout_coefficients(n1, n2)
    a1 * m2 * n2 + a2 * m1 * n1
  end

  def normalize_residue(r, mod) do
    cond do
      r < 0 -> normalize_residue(r + mod, mod)
      r > mod -> normalize_residue(r - mod, mod)
      true -> r
    end
  end

  def coprime?(a, b) do
    gcd(a, b) == 1
  end
end

Day13.part1() |> IO.inspect()
Day13.part2() |> IO.inspect()
