defmodule Beamer.Strip do
  require Record
  Record.defrecord(:digraph, Record.extract(:digraph, from_lib: "stdlib/src/digraph.erl"))

  def strip(graph) do
    [
      &without_isolated/1,
      &without_self_loop/1,
      &without_multiple_edges_to_same_node/1,
      &only_danger/1
    ]
    |> Enum.reduce([], fn fun, acc -> Enum.concat(acc, fun.(graph)) end)
  end

  defp without_isolated(graph) do
    vertices = :digraph.vertices(graph)
    all = MapSet.new(vertices)
    has_out = vertices |> :digraph_utils.reaching_neighbours(graph) |> MapSet.new()
    has_in = vertices |> :digraph_utils.reachable_neighbours(graph) |> MapSet.new()

    no_out = MapSet.difference(all, has_out)
    no_in = MapSet.difference(all, has_in)

    isolated = MapSet.intersection(no_out, no_in) |> MapSet.to_list()
    true = :digraph.del_vertices(graph, isolated)
    isolated
  end

  defp without_self_loop(graph) do
    short_loop_edges =
      digraph(graph)[:etab] |> :ets.select([{{:"$1", :"$2", :"$2", :_}, [], [:"$1"]}])

    true = :digraph.del_edges(graph, short_loop_edges)
    []
  end

  defp without_multiple_edges_to_same_node(graph) do
    excess_edges =
      graph
      |> :digraph.vertices()
      |> Stream.flat_map(fn v -> :digraph.out_edges(graph, v) end)
      |> Stream.map(fn e -> :digraph.edge(graph, e) end)
      |> Enum.group_by(fn {_, f, t, _} -> {f, t} end, fn {a, _, _, _} -> a end)
      |> Enum.reduce([], fn {_k, [_e | rest]}, acc -> Enum.concat(rest, acc) end)

    true = :digraph.del_edges(graph, excess_edges)
    []
  end

  defp only_danger(graph) do
    danger_modules = [
      :file
    ]

    all = graph |> :digraph.vertices() |> MapSet.new()

    on_danger_way =
      danger_modules
      |> Stream.flat_map(&find_module_calls(graph, &1))
      |> Stream.map(&all_on_path(graph, &1))
      |> Enum.reduce(fn p, acc -> MapSet.union(acc, p) end)

    quite_safe = MapSet.difference(all, on_danger_way) |> MapSet.to_list()

    true = :digraph.del_vertices(graph, quite_safe)
    quite_safe
  end

  defp find_module_calls(graph, module) do
    digraph(graph)[:vtab]
    |> :ets.select([{{{module, :_, :_}, :_}, [], [:"$_"]}])
    |> Stream.map(fn {n, _} -> n end)
  end

  defp all_on_path(graph, to) do
    :digraph.vertices(graph)
    |> Enum.reduce(
      MapSet.new([to]),
      fn v, acc ->
        if MapSet.member?(acc, v) do
          acc
        else
          case :digraph.get_path(graph, v, to) do
            false -> acc
            path -> MapSet.union(acc, MapSet.new(path))
          end
        end
      end
    )
  end
end
