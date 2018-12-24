defmodule Beamer do
  @moduledoc """
  Beamer -- BEAM disassembly examination.
  """

  alias Beamer.Disasm
  alias Beamer.Traverse

  def process(files) when is_list(files) do
    infoes =
      Enum.reduce(files, [], fn x, acc ->
        case Disasm.file(x) do
          {:ok, info} -> [info | acc]
          {:error, :not_a_beam_file, _} -> acc
        end
      end)

    Traverse.traverse(infoes)
  end

  def process(file) do
    process([file])
  end
end
