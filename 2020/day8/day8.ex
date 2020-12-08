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
end

Day8.part1() |> IO.inspect()
