defmodule Sleep do
  use FreeMonad, :m

  def sleep(amount), do: {Sleep, :sleep, [amount]}
  def time(), do: {Sleep, :time, []}

  def run({Sleep, :sleep, [amount]}), do: Process.sleep(amount)
  def run({Sleep, :time, []}), do: DateTime.utc_now() |> DateTime.to_unix(:milliseconds)
  def run({Sleep, :pure, [x]}), do: x
  def run({Sleep, :bind, [x, f]}) do
    xresult = run(x)
    fresult = f.(xresult)
    run(fresult)
  end
end

defmodule SleepSim do
  def run(now, {Sleep, :sleep, [amount]}), do: {now+amount, nil}
  def run(now, {Sleep, :time, []}),        do: {now, now}
  def run(now, {Sleep, :pure, [x]}),       do: {now, x}
  def run(now, {Sleep, :bind, [x, f]}) do
    {newtime, xresult} = run(now, x)
    fresult = f.(xresult)
    run(newtime, fresult)
  end
end
