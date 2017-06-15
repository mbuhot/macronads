defmodule Async do
  use Monad, :m

  def bind(x, f) do
    f.(Task.await(x))
  end
  def pure(x), do: Task.async(fn -> x end)
end
