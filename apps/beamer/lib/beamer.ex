defmodule Beamer do
  @moduledoc """
  Beamer -- BEAM disassembly examination.
  """

  alias Beamer.Disam
  alias Beamer.Traverse

  def process(file) do
    info = Disam.file(file)
    Traverse.traverse(info)
  end
end
