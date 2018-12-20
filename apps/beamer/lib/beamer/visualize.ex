defmodule Beamer.Visualize do
  alias Digraphviz.Converter
  alias Digraphviz.Types

  def to_dot(graph) do
    conv = Converter.from(graph)
    %{conv | node_converter: &node/2} |> Converter.convert(:digraph, node: [shape: :record])
  end

  defp node({module, _fun, _arity} = name, label) do
    label =
      if module == :file do
        [{:color, :red}, {:style, :filled} | label]
      else
        label
      end

    {[Types.ID.convert(name), Types.AttrsList.convert(label)], nil}
  end
end
