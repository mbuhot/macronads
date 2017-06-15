defmodule ListMonadTest do
  use ExUnit.Case, async: true

  test "list monad" do
    out =
      for x <- [1, 2, 3],
          y <- [7, 8, 9] do
        {x, y}
      end
    assert out == [{1, 7}, {1, 8}, {1, 9}, {2, 7}, {2, 8}, {2, 9}, {3, 7}, {3, 8}, {3, 9}]
  end

  test "MyList monad" do
    require ListMonad
    out = ListMonad.m do
      x <- [1, 2, 3]
      y <- [7, 8, 9]
      List.wrap({x, y})
    end

    assert out == [{1, 7}, {1, 8}, {1, 9}, {2, 7}, {2, 8}, {2, 9}, {3, 7}, {3, 8}, {3, 9}]
  end
end
