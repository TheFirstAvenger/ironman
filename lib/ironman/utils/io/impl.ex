defmodule Ironman.Utils.IO.Impl do
  @moduledoc false

  @callback get(out :: String.t()) :: String.t()
end
