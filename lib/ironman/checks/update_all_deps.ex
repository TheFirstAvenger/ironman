defmodule Ironman.Checks.UpdateAllDeps do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils.Deps

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{skipped_upgrades: skipped_upgrades} = config) do
    config
    |> Deps.get_installed_deps()
    |> Enum.map(&String.to_atom/1)
    |> Enum.reject(&Enum.member?(skipped_upgrades, &1))
    |> Enum.reduce({:skip, config}, fn dep, {ret, config} ->
      case Deps.check_dep_version(config, dep) do
        {:yes, config} -> {maximum(ret, :yes), config}
        {:no, config} -> {maximum(ret, :no), config}
        {:up_to_date, config} -> {maximum(ret, :up_to_date), config}
      end
    end)
  end

  defp maximum(x, y) when x == :yes or y == :yes, do: :yes
  defp maximum(x, y) when x == :no or y == :no, do: :no
  defp maximum(x, y) when x == :up_to_date or y == :up_to_date, do: :up_to_date
end
