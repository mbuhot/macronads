defmodule ListMonad do
  use Monad, :m

  def bind(x, f) do
    :lists.flatmap(f, x)
  end
  def pure(x), do: List.wrap(x)
end
