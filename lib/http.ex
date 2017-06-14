defmodule Http do
  use Monad, :http

  # API functions
  def get(url, query, headers), do: {:get, %{url: url, query: query, headers: headers}}
  def post(url, query, headers, body), do: {:post, %{url: url, query: query, headers: headers, body: body}}
  def pure(v), do: {:pure, %{val: v}}
  def bind(x, f), do: {:bind, %{val: x, next: f}}

  # Interpreter
  def runhttp(request = {:get, _}) do IO.puts("Getting: #{inspect(request)}"); {:ok, "Hello"} end
  def runhttp(request = {:post, _}) do IO.puts("Posting: #{inspect(request)}"); {:ok, "Thanks!"} end
  def runhttp({:pure, %{val: v}}) do {:ok, v} end
  def runhttp({:bind, %{val: x, next: f}}) do
    case runhttp(x) do
      {:error, reason} -> {:error, reason}
      {:ok, val} ->
        fval = f.(val)
        runhttp(fval)
    end
  end
end
