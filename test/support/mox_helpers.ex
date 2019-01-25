defmodule Ironman.Test.Helpers.MoxHelpers do
  @moduledoc false
  import Mox

  def expect_dep_http(dep, version) do
    expect_http("https://hex.pm/api/packages/#{dep}", %{"releases" => [%{"version" => version}]})
  end

  def expect_http(url, ret) do
    Ironman.MockHttpClient
    |> expect(:get_body_as_term, fn ^url -> {:ok, ret} end)
  end

  def expect_io(expect, return) do
    Ironman.MockIO
    |> expect(:get, fn ^expect -> "#{return}\n" end)
  end

  def expect_cmd(expect) do
    Ironman.MockCmd
    |> expect(:run, fn ^expect -> :ok end)
  end
end
