defmodule Day14 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    mask = 000000000000000000000000000000X1001X
    mem[42] = 100
    mask = 00000000000000000000000000000000X0XX
    mem[26] = 1
    """
  end

  @set_mask_pattern ~r/^mask = (?<mask>[01X]{36})$/
  @assignment_pattern ~r/^mem\[(?<addr>\d+)\] = (?<value>\d+)$/

  defp parse_program(text) do
    String.split(text, "\n", trim: true)
    |> Enum.map(fn line ->
      cond do
        Regex.match?(@set_mask_pattern, line) ->
          %{"mask" => mask} = Regex.named_captures(@set_mask_pattern, line)
          {:mask, parse_mask(mask)}

        Regex.match?(@assignment_pattern, line) ->
          %{"addr" => addr, "value" => value} = Regex.named_captures(@assignment_pattern, line)
          {:mem, String.to_integer(addr), String.to_integer(value)}
      end
    end)
  end

  defp parse_mask(mask) do
    String.codepoints(mask)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce([], fn {char, idx}, ops ->
      case char do
        "X" -> [{:float, idx} | ops]
        "0" -> [{:unset, idx} | ops]
        "1" -> [{:set, idx} | ops]
      end
    end)
  end

  defp apply_mask([], num) do
    num
  end

  defp apply_mask([{:float, _} | rest], num) do
    apply_mask(rest, num)
  end

  defp apply_mask([{:unset, idx} | rest], num) do
    apply_mask(rest, Bitwise.band(num, Bitwise.bnot(Bitwise.bsl(1, idx))))
  end

  defp apply_mask([{:set, idx} | rest], num) do
    apply_mask(rest, Bitwise.bor(num, Bitwise.bsl(1, idx)))
  end

  defp run([], {_, memory}) do
    memory
  end

  defp run([{:mask, mask} | rest], {_, memory}) do
    run(rest, {mask, memory})
  end

  defp run([{:mem, addr, value} | rest], {mask, memory}) do
    run(rest, {mask, assign(memory, addr, value, mask)})
  end

  defp assign(mem, addr, val, mask) do
    Map.put(mem, addr, apply_mask(mask, val))
  end

  def part1 do
    read_input()
    |> parse_program()
    |> run({nil, %{}})
    |> Enum.map(fn {_, val} -> val end)
    |> Enum.sum()
  end

  def part2 do
    read_input()
    |> parse_program()
    |> run_v2({nil, %{}})
    |> Enum.map(fn {_, val} -> val end)
    |> Enum.sum()
  end

  defp run_v2([], {_, memory}) do
    memory
  end

  defp run_v2([{:mask, mask} | rest], {_, memory}) do
    run_v2(rest, {mask, memory})
  end

  defp run_v2([{:mem, addr, value} | rest], {mask, memory}) do
    addrs = expand_float(mask, [apply_mask_v2(mask, addr)])

    memory =
      Enum.reduce(addrs, memory, fn addr, mem ->
        Map.put(mem, addr, value)
      end)

    run_v2(rest, {mask, memory})
  end

  defp expand_float([], addrs) do
    addrs
  end

  defp expand_float([{:float, idx} | rest], addrs) do
    addrs =
      Enum.reduce(addrs, [], fn addr, expanded ->
        [
          apply_mask([{:unset, idx}], addr),
          apply_mask([{:set, idx}], addr)
        ] ++ expanded
      end)

    expand_float(rest, addrs)
  end

  defp expand_float([{:set, _} | rest], addrs) do
    expand_float(rest, addrs)
  end

  defp expand_float([{:unset, _} | rest], addrs) do
    expand_float(rest, addrs)
  end

  defp apply_mask_v2([], num) do
    num
  end

  defp apply_mask_v2([{:float, _} | rest], num) do
    apply_mask_v2(rest, num)
  end

  defp apply_mask_v2([{:unset, _} | rest], num) do
    apply_mask_v2(rest, num)
  end

  defp apply_mask_v2([{:set, idx} | rest], num) do
    apply_mask_v2(rest, Bitwise.bor(num, Bitwise.bsl(1, idx)))
  end

  def debug do
    mask = parse_mask("000000000000000000000000000000X1001X")
    addr = 42
    expand_float(mask, [apply_mask_v2(mask, addr)])
  end
end

Day14.part1() |> IO.inspect()
Day14.part2() |> IO.inspect()
# Day14.debug() |> IO.inspect()
