defmodule Ironman.Utils.HttpClient do
  @moduledoc false
  @behaviour Ironman.Utils.HttpClient.Impl

  @spec get_body(String.t()) :: {:error, any()} | {:ok, String.t()}
  def get_body(url) do
    impl().get_body(url)
  end

  defp impl do
    Application.get_env(:ironman, :http_client, Ironman.Utils.HttpClient.DefaultImpl)
  end
end
