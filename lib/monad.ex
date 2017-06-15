defmodule Monad do

  def transform([expr], _mod), do: expr
  def transform([{:let, _, [{:=, _, [l, r]}]} | rest], mod) do
    tail = transform(rest, mod)
    quote do
      unquote(l) = unquote(r)
      unquote(tail)
    end
  end
  def transform([{:<-, _, [l, r]} | rest], mod) do
    tail = transform(rest, mod)
    mod.bind(r, l, tail)
  end
  def transform([expr | rest], mod) do
    transform([quote do _ <- unquote(expr) end | rest], mod)
  end

  defmacro __using__(name) do
    mod = __CALLER__.module
    quote do
      @mod unquote(mod)

      defmacro unquote(name)([do: {:__block__, _, exprs}]) do
        body = Monad.transform(exprs, unquote(mod))
        quote do
          import unquote(@mod), only: [pure: 1]
          unquote(body)
        end
      end

      def bind(x, as, rest) do
        quote do
          unquote(@mod).bind(unquote(x), fn unquote(as) -> unquote(rest) end)
        end
      end

      defoverridable [bind: 3]
    end
  end
end
