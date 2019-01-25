defmodule Ironman.Utils.HttpClient.Impl do
  @moduledoc false
  @callback get_body_as_term(url :: String.t()) :: {:error, any()} | {:ok, any()}
end
