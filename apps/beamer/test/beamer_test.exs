defmodule BeamerTest do
  use ExUnit.Case
  doctest Beamer

  test "greets the world" do
    assert Beamer.hello() == :world
  end
end
