defmodule Day8 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_program(text) do
    String.split(String.trim(text), "\n")
    |> Enum.map(fn line ->
      [op, val] = String.split(line)
      {op, String.to_integer(val)}
    end)
  end

  defp tick(program, pc, acc) do
    case Enum.at(program, pc) do
      {"nop", _} -> {pc + 1, acc}
      {"acc", int} -> {pc + 1, acc + int}
      {"jmp", int} -> {pc + int, acc}
    end
  end

  defp find_loop(program, pc, acc, history) do
    {next_pc, next_acc} = tick(program, pc, acc)
    count = Map.get(history, next_pc, 0)

    if count > 0 do
      acc
    else
      find_loop(program, next_pc, next_acc, Map.put(history, next_pc, count + 1))
    end
  end

  def part1 do
    program = parse_program(read_input())
    find_loop(program, 0, 0, %{})
  end

  def run(program, pc, acc, history, term_pc) do
    {next_pc, next_acc} = tick(program, pc, acc)
    count = Map.get(history, next_pc, 0)

    cond do
      count > 0 -> :loop
      next_pc == term_pc -> {:term, next_acc}
      next_pc > term_pc -> :wtf
      true -> run(program, next_pc, next_acc, Map.put(history, next_pc, count + 1), term_pc)
    end
  end

  def mod(program, ridx) do
    Enum.with_index(program)
    |> Enum.map(fn {{op, val}, idx} ->
      if idx == ridx do
        case op do
          "nop" -> {"jmp", val}
          "jmp" -> {"nop", val}
          _ -> {op, val}
        end
      else
        {op, val}
      end
    end)
  end

  def mods(program) do
    Stream.with_index(program)
    |> Stream.filter(fn {{op, _val}, _idx} ->
      case op do
        "acc" -> false
        "nop" -> true
        "jmp" -> true
      end
    end)
    |> Stream.map(fn {_, idx} -> mod(program, idx) end)
  end

  def part2 do
    program = parse_program(read_input())
    term_pc = Enum.count(program)

    Enum.reduce_while(mods(program), nil, fn modded_program, _ ->
      case run(modded_program, 0, 0, %{}, term_pc) do
        :loop -> {:cont, nil}
        {:term, acc} -> {:halt, acc}
      end
    end)
  end
end

Day8.part1() |> IO.inspect()
Day8.part2() |> IO.inspect()
