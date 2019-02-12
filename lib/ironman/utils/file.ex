defmodule Ironman.Utils.File do
  @moduledoc false
  @behaviour Ironman.Utils.File.Impl

  def exists?(path), do: impl().exists?(path)
  def read!(path), do: impl().read!(path)
  def write!(path, contents), do: impl().write!(path, contents)

  defp impl, do: Application.get_env(:ironman, :file, Ironman.Utils.File.DefaultImpl)
end
