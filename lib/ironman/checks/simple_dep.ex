defmodule Ironman.Checks.SimpleDep do
  @moduledoc false
  alias Ironman.Config
  alias Ironman.Utils.Deps

  @spec run(Config.t(), Deps.dep(), keyword()) :: {:error, any()} | {:no | :yes | :up_to_date | :skip, Config.t()}
  def run(%Config{} = config, dep, dep_opts \\ []) when is_atom(dep) and is_list(dep_opts) do
    Deps.check_dep_version(config, dep, dep_opts)
  end
end
