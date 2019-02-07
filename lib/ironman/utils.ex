defmodule Ironman.Utils do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils.{Cmd, Deps, HttpClient}
  alias Ironman.Utils.IO, as: IIO

  def puts(out) do
    if Mix.env() != :test do
      IO.puts(out)
    end
  end

  def check_self_version do
    {:ok, available} = Deps.available_version(:ironman)

    if available == Deps.ironman_version() do
      :ok
    else
      ask_self_upgrade()
    end
  end

  def ask_self_upgrade do
    ask(
      "Ironman is out of date. Upgrade?",
      fn -> upgrade_ironman() end,
      fn -> :declined end,
      fn -> ask_self_upgrade() end
    )
  end

  def upgrade_ironman do
    puts("Upgrading ironman")
    Cmd.run(["mix", "archive.install", "hex", "ironman", "--force"])
    puts("Ironman upgraded, please re-run.")
    :exit
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
    Cmd.run(["mix", "format"])
  end

  def run_mix_deps_get do
    puts("Running mix deps.get")
    Cmd.run(["mix", "deps.get"])
  end

  def run_mix_clean do
    puts("Running mix clean")
    Cmd.run(["mix", "clean", "--deps"])
  end

  @spec ask_mix_format() :: any()
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

  @spec get_body_as_term(String.t()) :: {:ok, any()} | {:error, any()}
  def get_body_as_term(url) do
    HttpClient.get_body_as_term(url)
  end

  @spec ask(String.t(), function(), function(), function()) :: any()
  def ask(q, yes, no, other) do
    case IIO.get("#{q} [Yn] ") do
      x when x in ["Y\n", "y\n", "\n"] -> yes.()
      x when x in ["N\n", "n\n"] -> no.()
      _ -> other.()
    end
  end
end
