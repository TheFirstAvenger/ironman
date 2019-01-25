defmodule Ironman.Utils.HttpClient do
  @moduledoc false
  @behaviour Ironman.Utils.HttpClient.Impl

  @spec get_body_as_term(String.t()) :: {:error, any()} | {:ok, any()}
  def get_body_as_term(url) do
    impl().get_body_as_term(url)
  end

  defp impl do
    Application.get_env(:ironman, :http_client, Ironman.Utils.HttpClient.DefaultImpl)
  end
end
