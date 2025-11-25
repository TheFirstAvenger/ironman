defmodule Ironman.Checks.DialyzerConfig do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils
  alias Ironman.Utils.Deps

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{} = config) do
    case Deps.get_configured_version(config, :dialyxir) do
      nil ->
        skip_install(config)

      _ ->
        config
        |> Config.get(:starting_project_config)
        |> Keyword.get(:dialyzer, nil)
        |> case do
          nil -> offer_add_dialyzer_config(config)
          _ -> {:up_to_date, config}
        end
    end
  end

  def offer_add_dialyzer_config(%Config{} = config) do
    Utils.ask(
      "Add dialyzer config to project?",
      fn -> do_add_config(config) end,
      fn -> decline_install(config) end
    )
  end

  def do_add_config(%Config{} = config) do
    config =
      config
      |> set_dialyzer_mix_exs()
      |> add_dialyzer_ignore_file()
      |> add_plt_to_gitignore()

    {:yes, config}
  end

  defp set_dialyzer_mix_exs(config) do
    mix_exs = Config.get(config, :mix_exs)
    mix_exs = Regex.replace(~r/def project do\n.*?\[/, mix_exs, "def project do\n [ " <> dialyzer_config(config))
    Config.set(config, :mix_exs, mix_exs)
  end

  defp add_dialyzer_ignore_file(config) do
    case Config.get(config, :dialyzer_ignore) do
      nil ->
        Utils.puts("Adding dialyzer ignore file")
        Config.set(config, :dialyzer_ignore, "[\n\n]")

      _ ->
        config
    end
  end

  defp dialyzer_config(config) do
    app_name = Config.app_name(config)

    """
    dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, "#{app_name}.plt"}
      ],
    """
  end

  defp add_plt_to_gitignore(config) do
    app_name = Config.app_name(config)
    gitignore = Config.get(config, :gitignore)

    cond do
      is_nil(gitignore) ->
        Utils.puts("Creating .gitignore with #{app_name}.plt")
        Config.set(config, :gitignore, "# dialyzer plt for CI caching\n#{app_name}.plt\n")

      String.contains?(gitignore, "#{app_name}.plt") ->
        config

      true ->
        Utils.puts("Adding #{app_name}.plt to .gitignore")
        newlines = if String.ends_with?(gitignore, "\n"), do: "", else: "\n\n"

        Config.set(
          config,
          :gitignore,
          "#{gitignore}#{newlines}# dialyzer plt\n#{app_name}.plt\n#{app_name}.plt.hash\n"
        )
    end
  end

  @spec skip_install(Config.t()) :: {:skip, Config.t()}
  def skip_install(%Config{} = config) do
    Utils.puts("\nSkipping dialyzer config")
    {:skip, config}
  end

  @spec decline_install(Config.t()) :: {:no, Config.t()}
  def decline_install(%Config{} = config) do
    Utils.puts("\nDeclined dialyzer config")
    {:no, config}
  end
end
