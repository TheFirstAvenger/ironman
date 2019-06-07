defmodule Ironman.Utils.Cmd.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.Cmd.Impl

  @spec run([String.t()]) :: {:ok, String.t()} | {:error, {non_neg_integer(), String.t()}}
  def run([h | t]) do
    case System.cmd(h, t, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, return_code} -> {:error, {return_code, output}}
    end
  end
end
