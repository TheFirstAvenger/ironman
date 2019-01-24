defmodule Ironman.Utils.HttpClient.Impl do
  @moduledoc false
  @callback get_body(url :: String.t()) :: {:error, any()} | {:ok, String.t()}
end
