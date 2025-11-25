defmodule Ironman.Utils.HttpClient.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.HttpClient.Impl

  alias Ironman.Utils.Deps

  # Credit to https://github.com/rrrene/credo
  @spec get_body_as_term(String.t()) :: {:error, any()} | {:ok, any()}
  def get_body_as_term(url) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    case :httpc.request(
           :get,
           {String.to_charlist(url), [{~c"User-Agent", user_agent()}, {~c"Accept", ~c"application/vnd.hex+erlang"}]},
           [],
           []
         ) do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, body |> IO.iodata_to_binary() |> :erlang.binary_to_term()}
      {:ok, {{_, 404, _}, _, _}} -> {:error, :not_found}
      err -> raise "httpc returned #{inspect(err)}"
    end
  end

  defp user_agent do
    ~c"Ironman/#{Deps.ironman_version()} (Elixir/#{System.version()}) (OTP/#{System.otp_release()})"
  end
end
