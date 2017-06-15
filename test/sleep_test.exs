defmodule SleepTest do
  use ExUnit.Case, async: true

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
end
