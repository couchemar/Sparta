defmodule Beamer.Traverse do
  def traverse(modules) when is_list(modules) do
    Enum.reduce(modules, {:digraph.new(), MapSet.new()}, fn m, acc -> traverse(m, acc) end)
  end

  def traverse(module_info) do
    traverse(module_info, {:digraph.new(), MapSet.new()})
  end

  defp traverse(module_info, acc) do
    do_traverse(module_info.funcs, module_info.module, acc)
  end

  defp do_traverse(funcs, module, acc) do
    do_funcs(funcs, module, acc)
  end

  defp do_funcs([], _module, acc), do: acc

  defp do_funcs([func | funcs], module, {graph, _} = acc) do
    {:function, name, arity, _line, instrs} = func
    full_name = {module, name, arity}
    _v = :digraph.add_vertex(graph, full_name, [:self])
    acc = do_instrs(instrs, full_name, acc)
    do_funcs(funcs, module, acc)
  end

  defp do_instrs(instrs, ctx, acc) do
    Enum.reduce(
      instrs,
      acc,
      fn instr, {graph, not_known} ->
        case i(instr) do
          :unknown ->
            {graph, not_known |> MapSet.put(instr)}

          nil ->
            acc

          cont ->
            graph = cont.(instr, ctx, graph)
            {graph, not_known}
        end
      end
    )
  end

  defp i({:label, _}), do: nil
  defp i({:line, _}), do: nil

  defp i({:func_info, {:atom, _module}, {:atom, _func}, _arity}),
    do: nil

  defp i({:test, _, _, _}), do: nil
  defp i({:select_val, _, _, _}), do: nil
  defp i({:move, _, _}), do: nil

  defp i({:call_ext_only, arity, {:extfunc, module, fun, arity}}) do
    fn _instr, caller, graph ->
      ext_call({module, fun, arity}, caller, graph)
    end
  end

  defp i(:return), do: nil
  defp i({:allocate, _, _}), do: nil

  defp i({:call_ext, arity, {:extfunc, module, fun, arity}}) do
    fn _instr, caller, graph ->
      ext_call({module, fun, arity}, caller, graph)
    end
  end

  defp i({:jump, _}), do: nil
  defp i({:gc_bif, _, _, _, _, _}), do: nil
  defp i({:bs_add, _, _, _}), do: nil
  defp i({:bs_init2, _, _, _, _, _, _}), do: nil
  defp i({:bs_put_string, _, _}), do: nil
  defp i({:bs_put_binary, _, _, _, _, _}), do: nil
  defp i({:put_map_assoc, _, _, _, _, _}), do: nil

  defp i({:call_ext_last, arity, {:extfunc, module, fun, arity}, _}) do
    fn _instr, caller, graph ->
      ext_call({module, fun, arity}, caller, graph)
    end
  end

  defp i(_), do: :unknown

  defp ext_call(callee, caller, graph) do
    callee = :digraph.add_vertex(graph, callee)
    _e = :digraph.add_edge(graph, caller, callee, [:ext_call])
    graph
  end
end
