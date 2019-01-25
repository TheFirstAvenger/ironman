defmodule Ironman.Utils.Cmd.Impl do
  @moduledoc false
  @callback run(args :: [String.t()]) :: :ok
end
