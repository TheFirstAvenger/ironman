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

  def raise_on_io do
    Ironman.MockIO
    |> expect(:get, fn x -> raise "IO.get(\"#{x}\")" end)
  end

  def expect_cmd(expect) do
    Ironman.MockCmd
    |> expect(:run, fn ^expect -> :ok end)
  end

  def expect_file_exists?(file, exists? \\ true) do
    Ironman.MockFile
    |> expect(:exists?, fn ^file -> exists? end)
  end

  def raise_on_file_exists? do
    Ironman.MockFile
    |> expect(:exists?, fn x -> raise "File.exists?(\"#{x}\")" end)
  end

  def expect_file_read!(file, content) do
    Ironman.MockFile
    |> expect(:read!, fn ^file -> content end)
  end

  def raise_on_file_read! do
    Ironman.MockFile
    |> expect(:read!, fn x -> raise "File.read!(\"#{x}\")" end)
  end

  def expect_file_write!(file, contents) do
    Ironman.MockFile
    |> expect(:write!, fn ^file, ^contents -> :ok end)
  end

  def raise_on_file_write! do
    Ironman.MockFile
    |> expect(:write!, fn x, y -> raise "File.write!(\"#{x}\", \"#{y}\")" end)
  end

  def raise_on_any_other do
    raise_on_file_exists?()
    raise_on_file_read!()
    raise_on_file_write!()
    raise_on_io()
  end
end
