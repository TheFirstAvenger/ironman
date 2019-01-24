defmodule Ironman do
  @moduledoc """
  Ironman suits up your mix project, protecting it from vulnerabilities by configuring best practices.
  """

  alias Ironman.Runner
  alias Ironman.Utils

  def run do
    Utils.puts("suiting up...")

    Runner.run()
  end
end
