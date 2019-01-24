defmodule Ironman do
  @moduledoc """
  Documentation for Ironman.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Ironman.hello()
      :world

  """

  alias Ironman.Runner
  alias Ironman.Utils

  def run do
    Utils.puts("suiting up...")

    Runner.run()
  end
end
