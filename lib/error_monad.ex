defmodule ErrorMonad do
  use Monad, :m

  def bind(x, as, rest) do
    quote do
      with {:ok, unquote(as)} <- unquote(x) do
        unquote(rest)
      end
    end
  end
  def pure(x), do: {:ok, x}
end
