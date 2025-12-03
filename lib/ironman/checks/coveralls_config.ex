defmodule Ironman.Checks.CoverallsConfig do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils
  alias Ironman.Utils.Deps

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{} = config) do
    case Deps.get_configured_version(config, :excoveralls) do
      nil ->
        skip_install(config)

      _ ->
        spc = Config.get(config, :starting_project_config)
        mix_exs = Config.get(config, :mix_exs)

        has_test_coverage = Keyword.get(spc, :test_coverage, nil) != nil
        has_cli_config = has_cli_preferred_envs?(mix_exs)

        if !has_test_coverage or !has_cli_config do
          offer_add_coveralls_config(config)
        else
          {:up_to_date, config}
        end
    end
  end

  defp has_cli_preferred_envs?(mix_exs) do
    # Check if def cli exists with preferred_envs containing coveralls
    Regex.match?(~r/def cli\b.*preferred_envs:.*coveralls/s, mix_exs)
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

    new_mix_exs =
      mix_exs
      |> insert_test_coverage_config()
      |> insert_cli_function()

    Config.set(config, :mix_exs, new_mix_exs)
  end

  defp insert_test_coverage_config(mix_exs) do
    if String.contains?(mix_exs, "test_coverage:") do
      mix_exs
    else
      pattern = ~r/(def project do\s*\[)/s
      replacement = "\\1\n" <> String.trim_trailing(test_coverage_config())
      Regex.replace(pattern, mix_exs, replacement, global: false)
    end
  end

  defp insert_cli_function(mix_exs) do
    if Regex.match?(~r/def cli\b/, mix_exs) do
      # def cli exists, update it to include preferred_envs if not present
      if String.contains?(mix_exs, "preferred_envs:") do
        mix_exs
      else
        # Add preferred_envs to existing def cli
        pattern = ~r/(def cli do\s*\[)/s
        replacement = "\\1\n" <> String.trim_trailing(preferred_envs_config())
        Regex.replace(pattern, mix_exs, replacement, global: false)
      end
    else
      # No def cli exists, add it before the end of the module
      pattern = ~r/(\n\s*end\s*)$/
      replacement = "\n" <> cli_function() <> "\\1"
      Regex.replace(pattern, mix_exs, replacement, global: false)
    end
  end

  defp set_coveralls_json(config) do
    case Config.get(config, :coveralls_json) do
      nil -> Config.set(config, :coveralls_json, coveralls_json())
      _ -> config
    end
  end

  defp test_coverage_config do
    """
      test_coverage: [tool: ExCoveralls],
    """
  end

  defp preferred_envs_config do
    """
      preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
    """
  end

  defp cli_function do
    """
      def cli do
        [
          preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
        ]
      end
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
