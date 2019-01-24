defmodule Ironman.Utils.HttpClient.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.HttpClient.Impl

  @spec get_body(String.t()) :: {:error, any()} | {:ok, String.t()}
  def get_body(url) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    case :httpc.request(:get, {String.to_charlist(url), [{'User-Agent', 'Elixir'}]}, [], []) do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, "#{body}"}
      {:ok, {{_, 404, _}, _, _}} -> {:error, :not_found}
      err -> raise "httpc returned #{inspect(err)}"
    end
  end
end
