defmodule Ironman.Utils.Cmd.Impl do
  @moduledoc false
  @callback run(args :: [String.t()]) :: {:ok, String.t()} | {:error, non_neg_integer()}
end
