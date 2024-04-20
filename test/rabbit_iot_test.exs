defmodule RabbitIotTest do
  use ExUnit.Case
  doctest RabbitIot

  test "greets the world" do
    assert RabbitIot.hello() == :world
  end
end
