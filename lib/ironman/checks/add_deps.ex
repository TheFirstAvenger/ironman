defmodule Ironman.Checks.AddDeps do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils
  alias Ironman.Utils.Deps
  alias Ironman.Utils.IO, as: IIO

  @spec run(Config.t()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{} = config) do
    case do_run(config, 0) do
      {config, 0} -> {:no, config}
      {config, _} -> {:yes, config}
    end
  end

  defp do_run(config, install_count) do
    Utils.ask(
      "Install any other dependencies?",
      fn -> ask_what_dep(config, install_count) end,
      fn -> {config, install_count} end
    )
  end

  defp ask_what_dep(config, install_count) do
    "What dependency? (e.g. ets)\n"
    |> IIO.get()
    |> String.trim()
    |> String.trim(":")
    |> String.to_atom()
    |> case do
      :"" -> do_run(config, install_count)
      dep -> check_dep(config, dep, install_count)
    end
  end

  defp check_dep(config, dep, install_count) do
    {config, increment} =
      case Deps.check_dep_version(config, dep) do
        {:yes, config} ->
          {config, true}

        {:error, :not_found} ->
          Utils.puts("#{dep} not found on hex.pm: https://hex.pm/packages/#{Atom.to_string(dep)}")
          {config, false}

        {x, config} when x in [:no, :up_to_date] ->
          {config, false}
      end

    install_count =
      if increment do
        install_count + 1
      else
        install_count
      end

    do_run(config, install_count)
  end
end
