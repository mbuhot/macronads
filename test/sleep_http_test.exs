defmodule SleepHttpTest do
  use ExUnit.Case, async: true

  defmodule SleepHttp do
    use FreeMonad, :m

    def bind(x = {m, _f, _a}, f) when m in [Sleep, Http, SleepHttp] do
      {__MODULE__, :bind, [x, f]}
    end
  end

  defmodule SleepHttpSim do
    def run(state, cmd = {Sleep, _f, _a}) do
      {newtime, result} = SleepSim.run(state.now, cmd)
      %{state | now: newtime, result: result}
    end
    def run(state, cmd = {Http, _f, _a}) do
      case HttpSim.run(cmd) do
        {:ok, res} -> %{state | result: res}
        {:error, res} -> %{state | result: nil, error: res}
      end
    end
    def run(state, {SleepHttp, :pure, [v]}), do: %{state | result: v}
    def run(state, {SleepHttp, :bind, [x, f]}) do
      newstate = run(state, x)
      case newstate.error do
        nil -> run(newstate, f.(newstate.result))
        _ -> newstate
      end
    end
  end

  def do_http_stuff do
    require Http

    Http.m do
      a <- Http.get("https://google.com", [q: "animals"], [])
      b <- Http.get("https://google.com", [q: "animals"], [])
      pure("#{a} and #{b}")
    end
  end

  def do_sleep_stuff do
    require Sleep

    Sleep.m do
      now1 <- Sleep.time
      Sleep.sleep 5000
      now2 <- Sleep.time
      pure(now2 - now1)
    end
  end

  test "Sleep With HTTP" do
    require SleepHttp
    require Sleep
    require Http

    program = SleepHttp.m do
      hits1 <- Http.m do
        a <- Http.get("https://google.com", [q: "animals"], [])
        b <- Http.get("https://google.com", [q: "animals"], [])
        Http.pure(a <> b)
      end
      do_http_stuff()
      Sleep.sleep(5000)
      hits2 <- do_http_stuff()
      do_sleep_stuff()
      SleepHttp.pure(hits1 <> hits2)
    end

    assert SleepHttpSim.run(%{now: 2000000, result: nil, error: nil}, program) == %{
      error: nil,
      now: 2010000,
      result: "HelloHelloHello and Hello"
    }
  end
end
