defmodule Ironman.Utils do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils.HttpClient
  alias Ironman.Utils.IO, as: IIO

  def puts(out) do
    if Mix.env() != :test do
      IO.puts(out)
    end
  end

  def check_mix_format do
    start = File.read!("mix.exs")
    run_mix_format()

    if start == File.read!("mix.exs") do
      :ok
    else
      ask_mix_format()
    end
  end

  def run_mix_format do
    puts("Running mix format...")
    System.cmd("mix", ["format"])
  end

  def run_mix_deps_get do
    puts("Running mix deps.get")
    System.cmd("mix", ["deps.get"])
  end

  def run_mix_clean do
    puts("Running mix clean")
    System.cmd("mix", ["clean", "--deps"])
  end

  def ask_mix_format do
    ask(
      "Mix format changed mix.exs, would you like to exit (to commit format changes separately)?",
      fn -> :exit end,
      fn -> :ok end,
      fn -> ask_mix_format() end
    )
  end

  @spec write_mix_exs(Config.t()) :: :ok
  def write_mix_exs(%Config{mix_exs: mix_exs}) do
    puts("Writing new mix.exs...")
    File.write!("mix.exs", mix_exs)
  end

  @spec get_body(String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_body(url) do
    HttpClient.get_body(url)
  end

  @spec ask(String.t(), function(), function(), function()) :: any()
  def ask(q, yes, no, other) do
    case IIO.get("#{q}\n") do
      x when x in ["Y\n", "y\n"] -> yes.()
      x when x in ["N\n", "n\n"] -> no.()
      _ -> other.()
    end
  end
end
