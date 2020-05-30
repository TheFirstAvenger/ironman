defmodule Ironman.Utils.File do
  @moduledoc false
  @behaviour Ironman.Utils.File.Impl

  def exists?(path), do: impl().exists?(path)
  def read!(path), do: impl().read!(path)
  def write!(path, contents), do: impl().write!(path, contents)
  def mkdir!(path), do: impl().mkdir!(path)
  def touch!(filename), do: impl().touch!(filename)

  defp impl, do: Application.get_env(:ironman, :file, Ironman.Utils.File.DefaultImpl)
end
