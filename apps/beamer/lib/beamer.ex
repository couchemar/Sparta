defmodule Beamer do
  @moduledoc """
  Beamer -- BEAM disassembly.
  """

  def process(file) do
    Beamer.Disam.file(file)
  end
end
