defmodule Mix.Tasks.SuitUp do
  @moduledoc false
  use Mix.Task

  def run(_) do
    Ironman.run()
  end
end
