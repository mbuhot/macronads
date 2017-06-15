defmodule HttpTest do
  use ExUnit.Case, async: true

  test "http" do
    require Http
    ast = Http.m do
      hits <- Http.get("https://google.com", [q: "animals"], [])
      res <- Http.post("https://mycoolapi.com", [], [authorization: "sup3rs3cret"], hits)
      let x = res <> hits
      baz <- Http.post("https://mycoolapi.com", [a: x], [], "")
      Http.pure baz
    end
    assert HttpSim.run(ast) == {:ok, "Thanks!"}
  end


  defmodule Petstore do
    use FreeMonad, :m
    def buy_a_dog(breed, age), do: {__MODULE__, :buy_a_dog, [breed, age]}
    def buy_a_cat(colour), do: {__MODULE__, :buy_a_cat, [colour]}
  end

  defmodule PetstoreAPI do
    def run({Petstore, :buy_a_dog, [breed, age]}) do
      Http.get("petstore.com/buy/dog", [breed: breed, age: age], [])
    end
    def run({Petstore, :buy_a_cat, [colour]}) do
      Http.get("petstore.com/buy/cat", [colour: colour], [])
    end
    def run({Petstore, :pure, [x]}), do: Http.pure(x)
    def run({Petstore, :bind, [x, f]}) do
      Http.bind(run(x), fn y -> run(f.(y)) end)
    end
  end

  test "Petstore API" do
    require Petstore

    program = Petstore.m do
      d <- Petstore.buy_a_dog("Shepard", 12)
      c <- Petstore.buy_a_cat("Ginger")
      pure([d, c])
    end

    evaluation =
      program
      |> PetstoreAPI.run()
      |> HttpSim.run()

    assert evaluation == {:ok, ["Hello", "Hello"]}
  end
end
