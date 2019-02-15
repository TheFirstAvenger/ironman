defmodule Ironman.Utils.Cmd.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.Cmd.Impl

  @spec run([String.t()]) :: :ok | :error
  def run([h | t]) do
    case System.cmd(h, t) do
      {_, 0} -> :ok
      _ -> :error
    end
  end
end
