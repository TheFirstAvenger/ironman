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
    expect(Ironman.MockHttpClient, :get_body_as_term, fn ^url -> {:ok, ret} end)
  end

  def expect_http_not_found(url) do
    expect(Ironman.MockHttpClient, :get_body_as_term, fn ^url -> {:error, :not_found} end)
  end

  def expect_io(expect, return) do
    expect(Ironman.MockIO, :get, fn ^expect -> "#{return}\n" end)
  end

  def expect_cmd(expect, return \\ {:ok, "all good"}) do
    expect(Ironman.MockCmd, :run, fn ^expect -> return end)
  end

  def expect_file_exists?(file, exists? \\ true) do
    expect(Ironman.MockFile, :exists?, fn ^file -> exists? end)
  end

  def expect_file_read!(file, content) do
    expect(Ironman.MockFile, :read!, fn ^file -> content end)
  end

  def expect_file_write!(file, contents) do
    expect(Ironman.MockFile, :write!, fn ^file, ^contents -> :ok end)
  end

  def expect_file_write!(file) do
    expect(Ironman.MockFile, :write!, fn ^file, _contents -> :ok end)
  end

  def expect_mkdir_p!(path) do
    expect(Ironman.MockFile, :mkdir_p!, fn ^path -> :ok end)
  end
end
