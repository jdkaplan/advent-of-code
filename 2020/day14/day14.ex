defmodule Day14 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp test_input do
    """
    mask = XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X
    mem[8] = 11
    mem[7] = 101
    mem[8] = 0
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

  defp pow(_base, 0) do
    1
  end

  defp pow(_base, exp) when exp < 0 do
    raise ArithmeticError, "negative exponents not supported"
  end

  defp pow(base, exp) when exp > 0 do
    List.duplicate(base, exp)
    |> Enum.reduce(1, &(&1 * &2))
  end

  defp parse_mask(mask) do
    String.codepoints(mask)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce([], fn {char, idx}, ops ->
      case char do
        "X" -> ops
        "0" -> [{:and, Bitwise.bnot(pow(2, idx))} | ops]
        "1" -> [{:or, pow(2, idx)} | ops]
      end
    end)
  end

  defp apply_mask([], num) do
    num
  end

  defp apply_mask([{:and, val} | rest], num) do
    apply_mask(rest, Bitwise.band(val, num))
  end

  defp apply_mask([{:or, val} | rest], num) do
    apply_mask(rest, Bitwise.bor(val, num))
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

  def debug do
    nil
  end
end

Day14.part1() |> IO.inspect()
Day14.debug() |> IO.inspect()
