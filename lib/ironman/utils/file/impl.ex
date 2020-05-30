defmodule Ironman.Utils.File.Impl do
  @moduledoc false

  @callback exists?(path :: String.t()) :: boolean()
  @callback read!(path :: String.t()) :: String.t()
  @callback write!(path :: String.t(), contents :: String.t()) :: :ok
  @callback mkdir!(path :: String.t()) :: :ok
  @callback touch!(filename :: String.t()) :: :ok
end
