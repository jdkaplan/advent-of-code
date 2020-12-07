defmodule DayX do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  def part1 do
    read_input()
  end
end

DayX.part1() |> IO.inspect()
