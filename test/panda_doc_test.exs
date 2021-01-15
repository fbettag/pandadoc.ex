defmodule PandaDocTest do
  use ExUnit.Case
  doctest PandaDoc

  test "greets the world" do
    assert PandaDoc.hello() == :world
  end
end
