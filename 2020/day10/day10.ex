defmodule Cache do
  use GenServer

  def start_link(cache) do
    GenServer.start_link(__MODULE__, cache)
  end

  def put(pid, key, val) do
    GenServer.call(pid, {:put, key, val})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  @impl true
  def init(cache) do
    {:ok, cache}
  end

  @impl true
  def handle_call({:get, key}, _from, cache) do
    {:reply, Map.get(cache, key), cache}
  end

  @impl true
  def handle_call({:put, key, val}, _from, cache) do
    {:reply, val, Map.put(cache, key, val)}
  end
end

defmodule Search do
  defp count_paths_iter(start, neighbors, cache) do
    cached = Cache.get(cache, start)

    if cached do
      cached
    else
      count =
        neighbors.(start)
        |> Enum.map(&count_paths_iter(&1, neighbors, cache))
        |> Enum.sum()

      Cache.put(cache, start, count)
    end
  end

  def count_paths(start, neighbors, goal) do
    {:ok, cache_pid} = Cache.start_link(%{goal => 1})
    count_paths_iter(start, neighbors, cache_pid)
  end
end

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

  def part2 do
    adapters = read_input() |> parse_adapters()
    device = Enum.max(adapters)

    neighbors = fn a1 -> Enum.filter(adapters, &can_stack?(a1, &1)) end
    Search.count_paths(0, neighbors, device)
  end
end

Day10.part1() |> IO.inspect()
Day10.part2() |> IO.inspect()
