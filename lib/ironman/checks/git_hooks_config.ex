defmodule Ironman.Checks.GitHooksConfig do
  @moduledoc false
  alias Ironman.{Config, Utils}
  alias Ironman.Utils.Deps

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date, Config.t()}
  def run(%Config{} = config) do
    dev_exs = Config.get(config, :config_dev_exs)

    if !dev_exs or !String.contains?(dev_exs, "config :git_hooks") do
      offer_add_githooks_config(config)
    else
      {:up_to_date, config}
    end
  end

  defp offer_add_githooks_config(%Config{} = config) do
    Utils.ask(
      "Add git_hooks config to project?",
      fn -> do_add_config(config) end,
      fn -> skip_install(config) end
    )
  end

  defp do_add_config(%Config{} = config) do
    config =
      config
      |> set_config_exs()
      |> set_config_dev_exs()
      |> set_config_prod_exs()
      |> set_config_test_exs()

    {:yes, config}
  end

  defp set_config_exs(config) do
    config_exs = Config.get(config, :config_exs)

    config_exs =
      if Regex.match?(~r/#\s+import_config "\#{Mix.env\(\)}.exs"/, config_exs) do
        Utils.puts("Uncommenting import_config in config.exs")
        Regex.replace(~r/#\s+import_config "\#{Mix.env\(\)}.exs"/, config_exs, "import_config \"\#{Mix.env()}.exs\"")
      else
        config_exs
      end

    Config.set(config, :config_exs, config_exs)
  end

  defp set_config_dev_exs(config) do
    new_config_exs =
      case Config.get(config, :config_dev_exs) do
        nil ->
          Utils.puts("Adding config/dev.exs")
          "use Mix.Config\n\n" <> git_hooks_config(config)

        config_dev_exs ->
          Utils.puts("Adding git_hooks_config to config/dev.exs")
          config_dev_exs <> "\n\n" <> git_hooks_config(config)
      end

    Config.set(config, :config_dev_exs, new_config_exs)
  end

  defp set_config_test_exs(config) do
    case Config.get(config, :config_test_exs) do
      nil ->
        Utils.puts("Adding config/test.exs")
        Config.set(config, :config_test_exs, "use Mix.Config\n\n")

      _ ->
        config
    end
  end

  defp set_config_prod_exs(config) do
    case Config.get(config, :config_prod_exs) do
      nil ->
        Utils.puts("Adding config/prod.exs")
        Config.set(config, :config_prod_exs, "use Mix.Config\n\n")

      _ ->
        config
    end
  end

  defp git_hooks_config(config) do
    tasks = ""

    tasks =
      if Deps.get_configured_version(config, :credo) do
        tasks <> "\n            \"credo --strict\","
      else
        tasks
      end

    tasks =
      if Deps.get_configured_version(config, :dialyxir) do
        tasks <> "\n            \"dialyzer --halt-exit-status\","
      else
        tasks
      end

    """
    config :git_hooks,
      hooks: [
        pre_commit: [
          verbose: true,
          mix_tasks: [
            "format --check-formatted --dry-run --check-equivalent"
          ]
        ],
        pre_push: [
          verbose: true,
          mix_tasks: [
            "compile --warnings-as-errors",#{tasks}
          ]
        ]
      ]
    """
  end

  @spec skip_install(Config.t()) :: {:no, Config.t()}
  def skip_install(%Config{} = config) do
    Utils.puts("\nSkipping git_hooks config")
    {:no, config}
  end
end
