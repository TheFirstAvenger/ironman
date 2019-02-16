defmodule Ironman.Utils.Cmd do
  @moduledoc false
  @behaviour Ironman.Utils.Cmd.Impl

  @spec run([String.t()]) :: :ok | :error
  def run(args) do
    impl().run(args)
  end

  defp impl do
    Application.get_env(:ironman, :cmd, Ironman.Utils.Cmd.DefaultImpl)
  end
end
