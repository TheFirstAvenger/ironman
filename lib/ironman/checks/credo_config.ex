defmodule Ironman.Checks.CredoConfig do
  @moduledoc false
  alias Ironman.{Config, Utils}
  alias Ironman.Utils.Deps

  @credo_config_filename Path.join([__DIR__, "../../../deps/credo/.credo.exs"])
  @default_credo_config_file File.read!(@credo_config_filename)

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{} = config) do
    case Deps.get_configured_version(config, :credo) do
      nil ->
        skip_install(config)

      _ ->
        case Config.get(config, :credo_exs) do
          nil -> offer_add_credo_config(config)
          _ -> {:up_to_date, config}
        end
    end
  end

  defp offer_add_credo_config(%Config{} = config) do
    Utils.ask(
      "Add credo config to project?",
      fn -> do_add_config(config) end,
      fn -> decline_install(config) end
    )
  end

  defp do_add_config(%Config{} = config) do
    Utils.puts "Adding credo config to project"
    config = Config.set(config, :credo_exs, @default_credo_config_file)
    {:yes, config}
  end

  @spec skip_install(Config.t()) :: {:skip, Config.t()}
  def skip_install(%Config{} = config) do
    Utils.puts("\nSkipping credo config")
    {:skip, config}
  end

  @spec decline_install(Config.t()) :: {:no, Config.t()}
  def decline_install(%Config{} = config) do
    Utils.puts("\nDeclined credo config")
    {:no, config}
  end
end
