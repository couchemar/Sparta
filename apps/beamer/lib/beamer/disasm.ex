defmodule Beamer.Disam do

  defmodule Beamer.Disam.Info do
    defstruct ~w(
      module
      funcs
      meta
    )a
  end

  def file(beamfile) do
    {:beam_file, module, _, meta1, meta2, funcs}= :beam_disasm.file(beamfile)

    %Beamer.Disam.Info{
      module: module,
      meta: meta1 ++ meta2,
      funcs: funcs
    }
  end

end
