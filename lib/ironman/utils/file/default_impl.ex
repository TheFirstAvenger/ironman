defmodule Ironman.Utils.File.DefaultImpl do
  @moduledoc false
  @behaviour Ironman.Utils.File.Impl

  def exists?(path), do: File.exists?(path)
  def read!(path), do: File.read!(path)
  def write!(path, contents), do: File.write!(path, contents)
  def mkdir!(path), do: File.mkdir!(path)
  def touch!(filename), do: File.touch!(filename)
end
