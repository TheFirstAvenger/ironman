defmodule Mix.Tasks.SuitUp do
  @shortdoc "Runs Ironman to suit up your mix project"
  @moduledoc false
  use Mix.Task

  @spec run(any()) :: nil | :ok | {:ok, binary()}
  def run(_) do
    Ironman.run()
  end
end
