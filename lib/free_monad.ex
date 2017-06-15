defmodule FreeMonad do
  defmacro __using__(name) do
    quote do
      use Monad, unquote(name)

      def pure(x), do: {__MODULE__, :pure, [x]}
      def bind(x = {__MODULE__, _, _}, f), do: {__MODULE__, :bind, [x, f]}

      defoverridable [pure: 1, bind: 2]
    end
  end
end
