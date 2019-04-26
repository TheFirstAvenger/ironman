defmodule Ironman.Utils do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils.Cmd, as: ICmd
  alias Ironman.Utils.Deps
  alias Ironman.Utils.File, as: IFile
  alias Ironman.Utils.HttpClient, as: IHttpClient
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
    {:ok, _} = ICmd.run(["mix", "archive.install", "hex", "ironman", "--force"])
    puts("Ironman upgraded, please run 'mix suit_up' again.")
    :exit
  end

  def check_mix_format do
    case ICmd.run(["mix", "format", "--check-formatted"]) do
      {:ok, _} -> :ok
      {:error, _} -> ask_mix_format()
    end
  end

  def run_mix_format do
    puts("Running mix format...")
    {:ok, _} = ICmd.run(["mix", "format"])
  end

  def check_git_status do
    case ICmd.run(["git", "status", "--porcelain"]) do
      {:ok, ""} ->
        :ok

      {:ok, _} ->
        ask(
          "You seem to have uncommitted files. Exit now so you can commit before continuing?",
          fn -> :exit end,
          fn -> :ok end
        )

      {:error, _} ->
        puts("Unable to check for uncommitted files (not a git repository)")
        :ok
    end
  rescue
    _ ->
      puts("Unable to check for uncommitted files (git not found)")
      :ok
  end

  def check_mix_exs do
    if IFile.exists?("mix.exs") do
      :ok
    else
      puts("No mix.exs file found, exiting.")
      :exit
    end
  end

  def run_mix_deps_get do
    puts("Running mix deps.get")
    {:ok, _} = ICmd.run(["mix", "deps.get"])
  end

  def run_mix_clean do
    puts("Running mix clean")
    {:ok, _} = ICmd.run(["mix", "clean", "--deps"])
  end

  @spec ask_mix_format() :: any()
  def ask_mix_format do
    ask(
      "Your files are not formatted. Mix Format needs to be run before continuing.",
      fn ->
        run_mix_format()

        ask(
          "Mix format complete. Exit now so you can commit the formatted version before continuing?",
          fn -> :exit end,
          fn -> :ok end
        )
      end,
      fn -> :exit end
    )
  end

  def write_changes(%Config{} = config) do
    puts("")
    write_if_changed(config, :mix_exs)
    write_if_changed(config, :gitignore)
    write_if_changed(config, :dialyzer_ignore)
    write_if_changed(config, :config_exs)
    write_if_changed(config, :config_dev_exs)
    write_if_changed(config, :config_test_exs)
    write_if_changed(config, :config_prod_exs)
    write_if_changed(config, :coveralls_json)
    write_if_changed(config, :credo_exs)
  end

  @spec write_if_changed(Config.t(), atom()) :: :ok
  defp write_if_changed(%Config{} = config, key) do
    if Config.changed?(config, key) do
      file = path_of(key)
      puts("Writing new #{file}...")
      IFile.write!(file, Config.get(config, key))
    end
  end

  def path_of(:mix_exs), do: "mix.exs"
  def path_of(:gitignore), do: ".gitignore"
  def path_of(:dialyzer_ignore), do: ".dialyzer_ignore.exs"
  def path_of(:credo_exs), do: ".credo.exs"
  def path_of(:coveralls_json), do: "coveralls.json"
  def path_of(:config_exs), do: "config/config.exs"
  def path_of(:config_dev_exs), do: "config/dev.exs"
  def path_of(:config_test_exs), do: "config/test.exs"
  def path_of(:config_prod_exs), do: "config/prod.exs"

  @spec get_body_as_term(String.t()) :: {:ok, any()} | {:error, any()}
  def get_body_as_term(url) do
    IHttpClient.get_body_as_term(url)
  end

  @spec ask(String.t(), function(), function()) :: any()
  def ask(q, yes, no) do
    case IIO.get("\n#{q} [Yn] ") do
      x when x in ["Y\n", "y\n", "\n"] -> yes.()
      x when x in ["N\n", "n\n"] -> no.()
      _ -> ask(q, yes, no)
    end
  end
end
