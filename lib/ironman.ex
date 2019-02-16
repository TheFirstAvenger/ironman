defmodule Ironman do
  @moduledoc """
  Ironman suits up your mix project, protecting it from vulnerabilities by configuring best practices.

  Install ironman by running:

  ```
  mix archive.install ironman
  ```

  and run it from the root of any project by calling:

  ```
  mix suit_up
  ```

  """

  alias Ironman.Runner
  alias Ironman.Utils

  def run do
    Utils.puts("\nSuiting up...")

    Runner.run()
  end
end
