defmodule Ironman.Checks.DialyzerConfig do
  @moduledoc false
  alias Ironman.{Config, Utils}

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date, Config.t()}
  def run(%Config{} = config) do
    config
    |> Config.starting_project_config()
    |> Keyword.get(:dialyzer, nil)
    |> case do
      nil -> offer_add_dialyzer_config(config)
      _ -> {:up_to_date, config}
    end
  end

  def offer_add_dialyzer_config(%Config{} = config) do
    Utils.ask(
      "Add dialyzer config to project?",
      fn -> do_add_config(config) end,
      fn -> skip_install(config) end
    )
  end

  def do_add_config(%Config{} = config) do
    config = set_dialyzer_mix_exs(config)

    config = add_dialyzer_ignore_file(config)

    config = add_plt_to_gitignore(config)

    {:yes, config}
  end

  defp set_dialyzer_mix_exs(config) do
    mix_exs = Config.mix_exs(config)
    mix_exs = Regex.replace(~r/def project do\n.*?\[/, mix_exs, "def project do\n [ " <> dialyzer_config(config))
    Config.set_mix_exs(config, mix_exs)
  end

  defp add_dialyzer_ignore_file(config) do
    case Config.dialyzer_ignore(config) do
      nil ->
        Utils.puts("Adding dialyzer ignore file")
        Config.set_dialyzer_ignore(config, "[\n\n]")

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

    case Config.gitignore(config) do
      nil ->
        Utils.puts("Creating .gitignore with #{app_name}.plt")
        Config.set_gitignore(config, "# dialyzer plt for CI caching\n#{app_name}.plt\n")

      gitignore ->
        if String.contains?(gitignore, "#{app_name}.plt") do
          config
        else
          Utils.puts("Adding #{app_name}.plt to .gitignore")

          newlines = if String.ends_with?(gitignore, "\n"), do: "", else: "\n\n"
          Config.set_gitignore(config, "#{gitignore}#{newlines}# dialyzer plt\n#{app_name}.plt\n")
        end
    end
  end

  @spec skip_install(Config.t()) :: {:no, Config.t()}
  def skip_install(%Config{} = config) do
    Utils.puts("Skipping dialyzer config")
    {:no, config}
  end
end
