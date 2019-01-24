defmodule Ironman.Test.Helpers.Utils do
  @moduledoc false
  import Mox

  def set_dep_http(dep, version) do
    set_http("https://hex.pm/api/packages/#{dep}", ~s({"releases":[{"version":") <> version <> ~s("}]}))
  end

  def set_http(url, ret) do
    Ironman.MockHttpClient
    |> expect(:get_body, fn ^url -> {:ok, ret} end)
  end

  def set_io(expect, return) do
    Ironman.MockIO
    |> expect(:get, fn ^expect -> "#{return}\n" end)
  end
end
