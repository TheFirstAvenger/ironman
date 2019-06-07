defmodule Mix.Tasks.SuitUp do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs Ironman to suit up your mix project"
  @spec run(any()) :: nil | :ok | {:ok, binary()}
  def run(_) do
    Ironman.run()
  end
end
