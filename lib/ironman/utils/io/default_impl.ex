defmodule Ironman.Utils.IO.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.IO.Impl

  @spec get(String.t()) :: String.t()
  def get(out) do
    IO.gets(out)
  end
end
