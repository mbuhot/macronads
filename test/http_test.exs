defmodule ListMonad do
  use Monad, :m

  def bind(x, f) do
    :lists.flatmap(f, x)
  end
end

defmodule ErrorMonad do
  use Monad, :m

  def bind(x, as, rest) do
    quote do
      with {:ok, unquote(as)} <- unquote(x) do
        unquote(rest)
      end
    end
  end
end

defmodule Async do
  use Monad, :m

  def bind(x, f) do
    f.(Task.await(x))
  end
end

defmodule SleepHttp do
  use Monad, :m

  def get(url, query, headers), do: {:httpcmd, Http.get(url, query, headers)}
  def post(url, query, headers, body), do: {:httpcmd, Http.post(url, query, headers, body)}

  def sleep(amount), do: {:sleepcmd, Sleep.sleep(amount)}
  def time(), do: {:sleepcmd, Sleep.time()}

  def pure(v), do: {:pure, %{val: v}}
  def bind(x, f), do: {:bind, %{val: x, next: f}}
end

defmodule FreeTest do
  use ExUnit.Case
  import Http, only: [http: 1]

  test "http" do
    ast = http do
      hits <- Http.get("https://google.com", [q: "animals"], [])
      res <- Http.post("https://mycoolapi.com", [], [authorization: "sup3rs3cret"], hits)
      let x = res <> hits
      baz <- Http.post("https://mycoolapi.com", [a: x], [], "")
      Http.pure baz
    end

    assert Http.runhttp(ast) == {:ok, "Thanks!"}
  end

  test "list monad" do
    out =
      for x <- [1, 2, 3],
          y <- [7, 8, 9] do
        {x, y}
      end
    assert out == [{1, 7}, {1, 8}, {1, 9}, {2, 7}, {2, 8}, {2, 9}, {3, 7}, {3, 8}, {3, 9}]
  end

  test "MyList monad" do
    require ListMonad
    out = ListMonad.m do
      x <- [1, 2, 3]
      y <- [7, 8, 9]
      List.wrap({x, y})
    end

    assert out == [{1, 7}, {1, 8}, {1, 9}, {2, 7}, {2, 8}, {2, 9}, {3, 7}, {3, 8}, {3, 9}]
  end

  def maybe_get_value(map, k) do
    if Map.has_key? map, k do
      {:ok, map[k]}
    else
      :error
    end
  end

  test "Maybe/Either monad" do
    res =
      with {:ok, x} <- maybe_get_value(%{a: 1}, :a),
           {:ok, y} <- maybe_get_value(%{a: 1}, :b) do
        x + y
      else
        :error -> 42
      end
    assert res == 42
  end

  test "Error monad" do
    require ErrorMonad

    res = ErrorMonad.m do
      x <- maybe_get_value(%{a: 1}, :a)
      y <- maybe_get_value(%{b: 2}, :b)
      {:ok, x + y}
    end

    assert res == {:ok, 3}
  end

  def do_stuff_async() do
    Task.async(fn -> 33 end)
  end

  test "Async Monad" do
    require Async

    res = Async.m do
      x <- do_stuff_async()
      y <- do_stuff_async()
      Task.async(fn -> x + y end)
    end

    assert Task.await(res) == 66
  end

  defmodule SleepSim do
    def run(now, {:sleep, amount}), do: {now+amount, nil}
    def run(now, {:time}),          do: {now, now}
    def run(now, {:pure, x}),       do: {now, x}
    def run(now, {:bind, x, f}) do
      {newtime, xresult} = run(now, x)
      fresult = f.(xresult)
      run(newtime, fresult)
    end
  end

  test "Sleep test" do
    require Sleep

    program = Sleep.m do
      now1 <- Sleep.time
      Sleep.sleep 5000
      now2 <- Sleep.time
      Sleep.pure(now2 - now1)
    end

    assert SleepSim.run(10000000, program) == {10005000, 5000}
    assert Sleep.run(program) > 5000
  end

  defmodule SleepHttpSim do
    def run(state, {:sleepcmd, cmd}) do
      {newtime, result} = SleepSim.run(state.now, cmd)
      %{state | now: newtime, result: result}
    end
    def run(state, {:httpcmd, cmd}) do
      case Http.runhttp(cmd) do
        {:ok, res} -> %{state | result: res}
        {:error, res} -> %{state | result: nil, error: res}
      end
    end
    def run(state, {:pure, %{val: v}}), do: %{state | result: v}
    def run(state, {:bind, %{val: x, next: f}}) do
      newstate = run(state, x)
      case newstate.error do
        nil -> run(newstate, f.(newstate.result))
        _ -> newstate
      end
    end
  end

  def do_http_stuff do
    require Http

    Http.http do
      a <- get("https://google.com", [q: "animals"], []))
      b <- get("https://google.com", [q: "animals"], []))
      Http.pure("#{a} and #{b}")
    end
  end

  def do_sleep_stuff do
    require Sleep

    Sleep.m do
      now1 <- Sleep.time
      Sleep.sleep 5000
      now2 <- Sleep.time
      Sleep.pure(now2 - now1)
    end
  end

  test "Sleep With HTTP" do
    require SleepHttp, as: SH

    program = SH.m do
      hits1 <- SH.get("https://google.com", [q: "animals"], [])
      SH.sleep(5000)
      hits2 <- SH.get("https://google.com", [q: "animals"], [])
      SH.sleep(5000)
      SH.pure(hits1 <> hits2)
    end

    assert SleepHttpSim.run(%{now: 2000000, result: nil, error: nil}, program) == %{error: nil, now: 2010000, result: "HelloHello"}
  end
end
