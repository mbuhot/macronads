defmodule Sleep do
  use Monad, :m

  def sleep(amount), do: {:sleep, amount}
  def time(), do: {:time}
  def pure(x), do: {:pure, x}
  def bind(x, f), do: {:bind, x, f}

  def run({:sleep, amount}), do: Process.sleep(amount)
  def run({:time}), do: DateTime.utc_now() |> DateTime.to_unix(:milliseconds)
  def run({:pure, x}), do: x
  def run({:bind, x, f}) do
    xresult = run(x)
    fresult = f.(xresult)
    run(fresult)
  end
end
