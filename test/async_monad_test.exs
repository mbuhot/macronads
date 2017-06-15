defmodule AsyncMonadTest do
  use ExUnit.Case, async: true

  def do_stuff_async() do
    Task.async(fn -> 33 end)
  end

  test "Async Monad" do
    require Async

    res = Async.m do
      x <- do_stuff_async()
      y <- do_stuff_async()
      Task.async(fn -> x + y end)
    end

    assert Task.await(res) == 66
  end
end
