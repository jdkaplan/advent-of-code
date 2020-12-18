defmodule NewMath do
  defmodule Integer do
    @enforce_keys [:value]
    defstruct [:value]
  end

  defmodule Plus do
    @enforce_keys [:lexpr, :rexpr]
    defstruct [:lexpr, :rexpr]
  end

  defmodule Times do
    @enforce_keys [:lexpr, :rexpr]
    defstruct [:lexpr, :rexpr]
  end

  defmodule Group do
    @enforce_keys [:expr]
    defstruct [:expr]
  end

  defmodule Expr do
    @enforce_keys [:expr]
    defstruct [:expr]
  end

  def tokenize(text) do
    scan(String.codepoints(text), [])
  end

  defp scan([], tokens) do
    Enum.reverse(tokens)
  end

  defp scan(text = [first | rest], tokens) do
    case first do
      "(" ->
        scan(rest, [:lparen | tokens])

      ")" ->
        scan(rest, [:rparen | tokens])

      "*" ->
        scan(rest, [:times | tokens])

      "+" ->
        scan(rest, [:plus | tokens])

      " " ->
        scan(rest, tokens)

      _ ->
        {digits, extra} = Enum.split_while(text, fn char -> String.match?(char, ~r/\d/) end)
        scan(extra, [{:integer, String.to_integer(Enum.join(digits))} | tokens])
    end
  end

  def parse(tokens) do
    [%Expr{expr: expr}] = parse_iter(tokens, [])
    expr
  end

  defp parse_iter([], stack) do
    stack
  end

  defp parse_iter(tokens, stack) do
    {rest, new_stack} = shift(tokens, stack)
    reduced = reduce(new_stack)
    parse_iter(rest, reduced)
  end

  defp shift([token | rest], stack) do
    gram =
      case token do
        {:integer, value} -> %Expr{expr: %Integer{value: value}}
        _ -> token
      end

    {rest, [gram | stack]}
  end

  defp reduce(stack) do
    case stack do
      [:rparen, %Expr{expr: expr}, :lparen | rest] ->
        new_expr = %Expr{expr: expr}
        reduce([new_expr | rest])

      [%Expr{expr: rexpr}, :plus, %Expr{expr: lexpr} | rest] ->
        new_expr = %Expr{expr: %Plus{lexpr: lexpr, rexpr: rexpr}}
        reduce([new_expr | rest])

      [%Expr{expr: rexpr}, :times, %Expr{expr: lexpr} | rest] ->
        new_expr = %Expr{expr: %Times{lexpr: lexpr, rexpr: rexpr}}
        reduce([new_expr | rest])

      _ ->
        stack
    end
  end

  def evaluate(%Plus{lexpr: lexpr, rexpr: rexpr}) do
    evaluate(lexpr) + evaluate(rexpr)
  end

  def evaluate(%Times{lexpr: lexpr, rexpr: rexpr}) do
    evaluate(lexpr) * evaluate(rexpr)
  end

  def evaluate(%Integer{value: value}) do
    value
  end
end

defmodule Day18 do
  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_expressions(text) do
    String.split(text, "\n", trim: true)
    |> Enum.map(&parse_expression/1)
  end

  defp parse_expression(line) do
    NewMath.tokenize(line)
    |> NewMath.parse()
  end

  defp test_input do
    """
    2 * 3 + (4 * 5)
    5 + (8 * 3 + 9 + 3 * 4 * 3)
    5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))
    ((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2
    """
  end

  def part1 do
    read_input()
    |> parse_expressions()
    |> Enum.map(&NewMath.evaluate/1)
    |> Enum.sum()
  end
end

Day18.part1() |> IO.inspect()
