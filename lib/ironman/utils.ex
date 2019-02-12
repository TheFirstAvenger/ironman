defmodule Ironman.Utils do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils.{Cmd, Deps, HttpClient}
  alias Ironman.Utils.File, as: IFile
  alias Ironman.Utils.IO, as: IIO

  def puts(out) do
    if Mix.env() != :test, do: IO.puts(out)
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
      fn -> :declined end
    )
  end

  def upgrade_ironman do
    puts("Upgrading ironman")
    Cmd.run(["mix", "archive.install", "hex", "ironman", "--force"])
    puts("Ironman upgraded, please re-run.")
    :exit
  end

  def check_mix_format do
    start = IFile.read!("mix.exs")
    run_mix_format()

    if start == IFile.read!("mix.exs") do
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
      fn -> :ok end
    )
  end

  def write_changes(%Config{} = config) do
    if Config.mix_exs_changed(config), do: write_mix_exs(config)
    if Config.gitignore_changed(config), do: write_gitignore(config)
    if Config.dialyzer_ignore_changed(config), do: write_dialyzer_ignore(config)

    Config.mix_exs_changed(config) or Config.gitignore_changed(config) or Config.dialyzer_ignore_changed(config)
  end

  @spec write_mix_exs(Config.t()) :: :ok
  defp write_mix_exs(%Config{} = config) do
    puts("Writing new mix.exs...")
    IFile.write!("mix.exs", Config.mix_exs(config))
  end

  @spec write_gitignore(Config.t()) :: :ok
  defp write_gitignore(%Config{} = config) do
    puts("Writing new gitignore...")
    IFile.write!(".gitignore", Config.gitignore(config))
  end

  @spec write_dialyzer_ignore(Config.t()) :: :ok
  defp write_dialyzer_ignore(%Config{} = config) do
    puts("Writing new dialyzer_ignore...")
    IFile.write!(".dialyzer_ignore.exs", Config.dialyzer_ignore(config))
  end

  @spec get_body_as_term(String.t()) :: {:ok, any()} | {:error, any()}
  def get_body_as_term(url) do
    HttpClient.get_body_as_term(url)
  end

  @spec ask(String.t(), function(), function()) :: any()
  def ask(q, yes, no) do
    case IIO.get("#{q} [Yn] ") do
      x when x in ["Y\n", "y\n", "\n"] -> yes.()
      x when x in ["N\n", "n\n"] -> no.()
      _ -> ask(q, yes, no)
    end
  end
end
