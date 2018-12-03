defmodule Beamer.Disasm do
  defmodule Beamer.Disasm.Info do
    defstruct ~w(
      module
      funcs
      meta
    )a
  end

  def file(beamfile) do
    case beamfile |> String.to_charlist() |> :beam_disasm.file() do
      {:beam_file, module, _, meta1, meta2, funcs} ->
        {:ok,
         %Beamer.Disasm.Info{
           module: module,
           meta: meta1 ++ meta2,
           funcs: funcs
         }}

      {:error, :beam_lib, {:file_error, _, :enoent}} ->
        {:error, :not_a_beam_file, beamfile}
    end
  end
end
