defmodule Http do
  use FreeMonad, :m

  def get(url, query, headers),        do: {Http, :get, [url, query, headers]}
  def post(url, query, headers, body), do: {Http, :post, [url, query, headers, body]}
end

defmodule HttpSim do
  def run({Http, :get, _}) do {:ok, "Hello"} end
  def run({Http, :post, _}) do {:ok, "Thanks!"} end
  def run({Http, :pure, [v]}) do {:ok, v} end
  def run({Http, :bind, [x, f]}) do
    case run(x) do
      {:error, reason} -> {:error, reason}
      {:ok, val} ->
        fval = f.(val)
        run(fval)
    end
  end
end
