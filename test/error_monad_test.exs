defmodule ErrorMonadTest do
  use ExUnit.Case, async: true

  def maybe_get_value(map, k) do
    if Map.has_key? map, k do
      {:ok, map[k]}
    else
      :error
    end
  end

  test "Maybe/Either monad" do
    res =
      with {:ok, x} <- maybe_get_value(%{a: 1}, :a),
           {:ok, y} <- maybe_get_value(%{a: 1}, :b) do
        x + y
      else
        :error -> 42
      end
    assert res == 42
  end

  test "Error monad" do
    require ErrorMonad

    res = ErrorMonad.m do
      x <- maybe_get_value(%{a: 1}, :a)
      y <- maybe_get_value(%{b: 2}, :b)
      {:ok, x + y}
    end

    assert res == {:ok, 3}
  end
end
