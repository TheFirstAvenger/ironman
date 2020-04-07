defmodule Ironman.Checks.UpdateAllDeps do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils
  alias Ironman.Utils.Deps

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{skipped_upgrades: skipped_upgrades} = config) do
    Utils.ask(
      "Check all deps for updates?",
      fn -> do_check_all_deps(config, skipped_upgrades) end,
      fn -> decline_install(config) end
    )
  end

  defp do_check_all_deps(config, skipped_upgrades) do
    config
    |> Deps.get_installed_deps()
    |> Enum.map(&String.to_atom/1)
    |> Enum.reject(&Enum.member?(skipped_upgrades, &1))
    |> Enum.reduce({:skip, config}, fn dep, {ret, config} ->
      case Deps.check_dep_version(config, dep) do
        {:yes, config} ->
          {maximum(ret, :yes), config}

        {:no, config} ->
          {maximum(ret, :no), config}

        {:up_to_date, config} ->
          {maximum(ret, :up_to_date), config}

        {:error, :not_found} ->
          Utils.puts("WARNING: Could not find dep #{dep}, please check that it is available on hex")
          {maximum(ret, :up_to_date), config}
      end
    end)
  end

  @spec decline_install(Config.t()) :: {:no, Config.t()}
  def decline_install(%Config{} = config) do
    Utils.puts("\nDeclined checking all deps for update")
    {:no, config}
  end

  defp maximum(x, y) when x == :yes or y == :yes, do: :yes
  defp maximum(x, y) when x == :no or y == :no, do: :no
  defp maximum(x, y) when x == :up_to_date or y == :up_to_date, do: :up_to_date
end
