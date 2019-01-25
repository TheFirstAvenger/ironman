defmodule Ironman.Utils.Cmd.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.Cmd.Impl

  @spec run([String.t()]) :: :ok
  def run([h | t]) do
    {_, 0} = System.cmd(h, t)
    :ok
  end
end
