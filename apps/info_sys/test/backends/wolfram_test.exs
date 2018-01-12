defmodule InfoSys.Backends.WolframTest do
  use ExUnit.Case, async: true
  alias InfoSys.Wolfram

  test "makes request, reports results, then terminates" do
    ref = make_ref()
    {:ok, pid} = Wolfram.start_link("Ruby+creator", ref, self(), 1)
    Process.monitor(pid)

    assert_receive {:results, ^ref, [
                       %InfoSys.Result{
                         backend: "wolfram",
                         score: 95,
                         text: "Yukihiro Matsumoto",
                         url: nil}
                     ]}
    assert_receive {:DOWN, _ref, :process, ^pid, :normal}
  end

  test "no query results reports an empty list" do
    ref = make_ref()
    {:ok, pid} = Wolfram.start_link("none", ref, self(), 1)

    assert_receive {:results, ^ref, []}
  end
end
