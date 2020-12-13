defmodule Numbers do
  use GenServer

  def start_link do
    primes = [2, 3]
    max_n = 2
    GenServer.start_link(__MODULE__, {primes, max_n})
  end

  def is_prime?(pid, n) do
    GenServer.call(pid, {:is_prime?, n})
  end

  def primes_up_to(pid, n) do
    GenServer.call(pid, {:up_to, n})
  end

  @impl true
  def init(primes) do
    {:ok, primes}
  end

  @impl true
  def handle_call({:is_prime?, n}, _from, {primes, max_n}) do
    IO.inspect({:is_prime?, n, {primes, max_n}})
    {ans, {primes, max_n}} = check_prime(n, {primes, max_n})
    {:reply, ans, {primes, max_n}}
  end

  @impl true
  def handle_call({:up_to, n}, _from, {primes, max_n}) do
    {ans, {primes, max_n}} = gen_primes(n, {primes, max_n})
    {:reply, ans, {primes, max_n}}
  end

  defp check_prime(n, {primes, max_n}) do
    if n / 2 <= max_n do
      {Enum.member?(primes, n), {primes, max_n}}
    else
      possible_factors = primes ++ Enum.to_list((max_n + 1)..div(n, 2))
      has_factor = Enum.any?(possible_factors, &(rem(n, &1) == 0))
      {!has_factor, {primes, max_n}}
    end
  end

  defp gen_primes(n, {primes, max_n}) do
    if n <= max_n do
      {Enum.filter(primes, &(&1 <= n)), {primes, max_n}}
    else
      new_primes =
        Enum.reduce((max_n + 1)..n, primes, fn p, primes ->
          {is_prime, {primes, _}} = check_prime(p, {primes, p - 1})

          if is_prime do
            primes ++ [p]
          else
            primes
          end
        end)

      {new_primes, {new_primes, n}}
    end
  end
end

defmodule Day13 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    939
    7,13,x,x,59,x,31,19
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

  # defp lcm(a, b, numbers) do
  #   bag_union(factors(a, numbers), factors(b, numbers))
  # end

  # defp factors(n, numbers) do
  #   Numbers.primes_up_to(numbers, div(n, 2))
  #   |> Enum.reduce(2..n, {n, %{}}, fn )
  # end

  # defp bag_union(b1, b2) do
  #   Enum.reduce(b1, b2, fn {k, v}, bag ->
  #     Map.put(bag, k, max(v, Map.get(bag, k, 0)))
  #   end)
  # end

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
end

Day13.part1() |> IO.inspect()
