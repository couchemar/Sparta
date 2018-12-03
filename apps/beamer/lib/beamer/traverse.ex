defmodule Beamer.Traverse do
  def traverse(modules) when is_list(modules) do
    graph = :digraph.new()

    for module_info <- modules do
      traverse(module_info, graph)
    end

    graph
  end

  def traverse(module_info) do
    traverse(module_info, :digraph.new())
  end

  defp traverse(module_info, graph) do
    do_traverse(module_info.funcs, module_info.module, graph)
  end

  defp do_traverse(funcs, module, graph) do
    do_funcs(funcs, module, graph)
  end

  defp do_funcs([], _module, graph), do: graph

  defp do_funcs([func | funcs], module, graph) do
    {:function, name, arity, _line, instrs} = func
    full_name = {module, name, arity}
    _v = :digraph.add_vertex(graph, full_name, [:self])
    graph1 = do_instrs(instrs, full_name, graph)
    do_funcs(funcs, module, graph1)
  end

  defp do_instrs([], _ctx, graph), do: graph

  defp do_instrs([instr | instrs], ctx, graph) do
    graph1 = i(instr, ctx, graph)
    do_instrs(instrs, ctx, graph1)
  end

  defp i({:label, _}, _ctx, graph), do: graph
  defp i({:line, _}, _ctx, graph), do: graph

  defp i(
         {:func_info, {:atom, module}, {:atom, func}, arity},
         {module, func, arity},
         graph
       ),
       do: graph

  defp i({:test, _, _, _}, _ctx, graph), do: graph
  defp i({:select_val, _, _, _}, _ctx, graph), do: graph
  defp i({:move, _, _}, _ctx, graph), do: graph

  defp i({:call_ext_only, arity, {:extfunc, module, fun, arity}}, caller, graph) do
    ext_call({module, fun, arity}, caller, graph)
  end

  defp i(:return, _ctx, graph), do: graph
  defp i({:allocate, _, _}, _ctx, graph), do: graph

  defp i({:call_ext, arity, {:extfunc, module, fun, arity}}, caller, graph) do
    ext_call({module, fun, arity}, caller, graph)
  end

  defp i({:jump, _}, _ctx, graph), do: graph
  defp i({:gc_bif, _, _, _, _, _}, _ctx, graph), do: graph
  defp i({:bs_add, _, _, _}, _ctx, graph), do: graph
  defp i({:bs_init2, _, _, _, _, _, _}, _ctx, graph), do: graph
  defp i({:bs_put_string, _, _}, _ctx, graph), do: graph
  defp i({:bs_put_binary, _, _, _, _, _}, _ctx, graph), do: graph
  defp i({:put_map_assoc, _, _, _, _, _}, _ctx, graph), do: graph

  defp i({:call_ext_last, arity, {:extfunc, module, fun, arity}, _}, caller, graph) do
    ext_call({module, fun, arity}, caller, graph)
  end

  defp ext_call(callee, caller, graph) do
    callee = :digraph.add_vertex(graph, callee)
    _e = :digraph.add_edge(graph, caller, callee, [:ext_call])
    graph
  end
end
