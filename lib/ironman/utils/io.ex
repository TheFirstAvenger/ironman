defmodule Ironman.Utils.IO do
  @moduledoc false

  @behaviour Ironman.Utils.IO.Impl

  @spec get(String.t()) :: String.t()
  def get(out) do
    impl().get(out)
  end

  defp impl do
    Application.get_env(:ironman, :io, Ironman.Utils.IO.DefaultImpl)
  end
end
