defmodule Day20 do
  defmodule Tile do
    @enforce_keys [:id, :rows]
    defstruct [:id, :rows]

    def row(tile, idx) do
      Enum.at(tile.rows, idx)
    end

    def col(tile, idx) do
      Enum.map(tile.rows, fn row ->
        String.at(row, idx)
      end)
      |> Enum.join()
    end

    def size(tile) do
      String.length(row(tile, 0))
    end

    def side_hash(text) do
      min(binary(text), binary(String.reverse(text)))
    end

    defp binary(text) do
      String.codepoints(text)
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn {char, idx} ->
        case char do
          "#" -> Bitwise.bsl(1, idx)
          "." -> 0
        end
      end)
      |> Enum.sum()
    end

    defp top(t), do: row(t, 0)
    defp right(t), do: col(t, 0)
    defp bottom(t), do: row(t, -1)
    defp left(t), do: col(t, -1)

    def sides(tile) do
      [
        top(tile),
        right(tile),
        bottom(tile),
        left(tile)
      ]
    end

    def matching_side?(t1, t2) do
      h1 = sides(t1) |> Enum.map(&side_hash/1)
      h2 = sides(t2) |> Enum.map(&side_hash/1)
      uniq = MapSet.new(h1 ++ h2) |> MapSet.size()
      uniq < Enum.count(h1) + Enum.count(h2)
    end

    def transformations do
      [
        :f0,
        :f90,
        :f180,
        :f270,
        :b0,
        :b90,
        :b180,
        :b270
      ]
    end

    defp flip(tile) do
      %Tile{id: tile.id, rows: Enum.reverse(tile.rows)}
    end

    defp rotate(tile) do
      l = size(tile)
      new_rows = Enum.map(1..l, &col(tile, l - &1))
      %Tile{id: tile.id, rows: new_rows}
    end

    def transform(tile, op) do
      case op do
        :f0 -> tile
        :f90 -> rotate(tile)
        :f180 -> rotate(rotate(tile))
        :f270 -> rotate(rotate(rotate(tile)))
        :b0 -> flip(tile)
        :b90 -> flip(rotate(tile))
        :b180 -> flip(rotate(rotate(tile)))
        :b270 -> flip(rotate(rotate(rotate(tile))))
      end
    end

    def fits?(%Tile{}, nil), do: true
    def fits?(t1, :below, t2), do: top(t1) == bottom(t2)
    def fits?(t1, :above, t2), do: bottom(t1) == top(t2)
    def fits?(t1, :leftof, t2), do: right(t1) == left(t2)
    def fits?(t1, :rightof, t2), do: left(t1) == right(t2)
  end

  defmodule Grid do
    @enforce_keys [:size, :map]
    defstruct [:size, :map]

    def full?(grid) do
      for r <- 0..(grid.size - 1) do
        for c <- 0..(grid.size - 1) do
          {r, c}
        end
      end
      |> Enum.all?(&Map.get(grid.map, &1))
    end

    def empty(size), do: %Grid{size: size, map: %{}}

    def corners(grid) do
      Enum.map(
        [
          {0, 0},
          {0, grid.size - 1},
          {grid.size - 1, 0},
          {grid.size - 1, grid.size - 1}
        ],
        &Map.get(grid.map, &1)
      )
    end

    def fill_candidates(grid) do
      for r <- 0..grid.size(-1),
          c <- 0..(grid.size - 1) do
        case Map.get(grid.map, {r, c}) do
          nil ->
            []

          _ ->
            [
              [
                {r + 1, c},
                {r - 1, c},
                {r, c + 1},
                {r, c - 1}
              ]
            ]
        end
      end
      |> Enum.concat()
      |> Enum.uniq()
      |> Enum.filter(&can_fill?(grid, &1))
    end

    defp can_fill?(grid, cell) do
      in_bounds?(grid, cell) and Map.get(grid.map, cell) == nil
    end

    defp in_bounds?(%Grid{size: size}, {r, c}) do
      0 <= r and r < size and 0 <= c and c < size
    end

    def tile_ids(grid) do
      Enum.map(grid.map, fn {_, {%Tile{id: id}, _op}} -> id end)
    end

    def can_place?(grid, tile, op, {r, c}) do
      north = Map.get(grid.map, {r - 1, c})
      south = Map.get(grid.map, {r + 1, c})
      east = Map.get(grid.map, {r, c + 1})
      west = Map.get(grid.map, {r, c - 1})

      Enum.all?([
        fits?({tile, op}, :below, north),
        fits?({tile, op}, :above, south),
        fits?({tile, op}, :leftof, east),
        fits?({tile, op}, :rightof, west)
      ])
    end

    defp fits?({_tile, _t_op}, _rel, nil), do: true

    defp fits?({tile, t_op}, rel, {neighbor, n_op}) do
      t = Tile.transform(tile, t_op)
      n = Tile.transform(neighbor, n_op)
      Tile.fits?(t, rel, n)
    end

    def place(grid, tile, op, rc) do
      %{grid | map: Map.put(grid.map, rc, {tile, op})}
    end

    def show(grid, tile_size) do
      for grid_r <- 0..(grid.size - 1) do
        for tile_r <- 0..(tile_size - 1) do
          for grid_c <- 0..(grid.size - 1) do
            case Map.get(grid.map, {grid_r, grid_c}) do
              {tile, op} -> Tile.transform(tile, op) |> Tile.row(tile_r)
              nil -> Enum.join(List.duplicate("o", tile_size))
            end
          end
          |> Enum.join(" ")
        end
        |> Enum.join("\n")
      end
      |> Enum.join("\n\n")
      |> IO.puts()
    end
  end

  defp read_input do
    Path.expand('input', Path.dirname(__ENV__.file))
    |> File.read!()
  end

  defp parse_tiles(text) do
    text
    |> String.split("\n\n", trim: true)
    |> Enum.map(&String.split(&1, "\n", trim: true))
    |> Enum.map(fn [title | lines] ->
      # Tile 1234:
      id = String.slice(title, 5..-2)
      %Tile{id: String.to_integer(id), rows: lines}
    end)
  end

  def part1 do
    read_input()
    |> parse_tiles()
    |> neighbor_counts()
    |> Enum.filter(fn {_id, count} -> count == 2 end)
    |> Enum.reduce(1, fn {id, _}, prod -> id * prod end)
  end

  defp neighbor_counts(tileset) do
    for tile <- tileset do
      count =
        Enum.count(tileset -- [tile], fn neighbor ->
          Tile.matching_side?(tile, neighbor)
        end)

      {tile.id, count}
    end
    |> Enum.into(%{})
  end
end

Day20.part1() |> IO.inspect()
