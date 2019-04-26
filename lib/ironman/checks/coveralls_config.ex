defmodule Ironman.Checks.CoverallsConfig do
  @moduledoc false
  alias Ironman.{Config, Utils}
  alias Ironman.Utils.Deps

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{} = config) do
    case Deps.get_configured_version(config, :excoveralls) do
      nil ->
        skip_install(config)

      _ ->
        spc = Config.get(config, :starting_project_config)

        if !Keyword.get(spc, :test_coverage, nil) or !Keyword.get(spc, :preferred_cli_env, nil) do
          offer_add_coveralls_config(config)
        else
          {:up_to_date, config}
        end
    end
  end

  def offer_add_coveralls_config(%Config{} = config) do
    Utils.ask(
      "Add coveralls config to project?",
      fn -> do_add_config(config) end,
      fn -> decline_install(config) end
    )
  end

  def do_add_config(%Config{} = config) do
    Utils.puts("Adding coveralls config to project")

    config =
      config
      |> set_coveralls_mix_exs()
      |> set_coveralls_json()

    {:yes, config}
  end

  defp set_coveralls_mix_exs(config) do
    mix_exs = Config.get(config, :mix_exs)
    mix_exs = Regex.replace(~r/def project do\n.*?\[/, mix_exs, "def project do\n [ " <> coveralls_config())
    Config.set(config, :mix_exs, mix_exs)
  end

  defp set_coveralls_json(config) do
    case Config.get(config, :coveralls_json) do
      nil -> Config.set(config, :coveralls_json, coveralls_json())
      _ -> config
    end
  end

  defp coveralls_config do
    """
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
    """
  end

  defp coveralls_json, do: "{\n  \"skip_files\": []\n}"

  @spec skip_install(Config.t()) :: {:skip, Config.t()}
  def skip_install(%Config{} = config) do
    Utils.puts("\nSkipping coveralls config")
    {:skip, config}
  end

  @spec decline_install(Config.t()) :: {:no, Config.t()}
  def decline_install(%Config{} = config) do
    Utils.puts("\nDeclined coveralls config")
    {:no, config}
  end
end
