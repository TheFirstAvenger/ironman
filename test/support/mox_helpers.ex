defmodule Ironman.Test.Helpers.MoxHelpers do
  @moduledoc false
  import Mox

  def expect_dep_http(dep, version) do
    expect_http("https://hex.pm/api/packages/#{dep}", %{"releases" => [%{"version" => version}]})
  end

  def expect_dep_http_not_found(dep) do
    expect_http_not_found("https://hex.pm/api/packages/#{dep}")
  end

  def expect_http(url, ret) do
    Ironman.MockHttpClient
    |> expect(:get_body_as_term, fn ^url -> {:ok, ret} end)
  end

  def expect_http_not_found(url) do
    Ironman.MockHttpClient
    |> expect(:get_body_as_term, fn ^url -> {:error, :not_found} end)
  end

  def expect_io(expect, return) do
    Ironman.MockIO
    |> expect(:get, fn ^expect -> "#{return}\n" end)
  end

  def expect_cmd(expect, return \\ {:ok, "all good"}) do
    Ironman.MockCmd
    |> expect(:run, fn ^expect -> return end)
  end

  def expect_file_exists?(file, exists? \\ true) do
    Ironman.MockFile
    |> expect(:exists?, fn ^file -> exists? end)
  end

  def expect_file_read!(file, content) do
    Ironman.MockFile
    |> expect(:read!, fn ^file -> content end)
  end

  def expect_file_write!(file, contents) do
    Ironman.MockFile
    |> expect(:write!, fn ^file, ^contents -> :ok end)
  end
end
