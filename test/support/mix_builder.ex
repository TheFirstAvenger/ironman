defmodule Ironman.Test.Helpers.MixBuilder do
  @moduledoc false
  alias Ironman.Config

  def with_deps(deps \\ []) when is_list(deps) do
    mix_exs =
      """
      defmodule Test.MixProject do
      use Mix.Project

      def project do
      [
        app: :test,
        version: "0.1.0",
        elixir: "~> 1.8",
        start_permanent: Mix.env() == :prod,
        deps: deps()
      ]
      end

      # Run "mix help deps" to learn about dependencies.
      defp deps do
        #{mix_string(deps)}
      end
      end
      """
      |> Code.format_string!()
      |> List.wrap()
      |> IO.iodata_to_binary()

    %Config{mix_exs: mix_exs}
  end

  @spec mix_string(list()) :: String.t()
  def mix_string(deps) do
    deps
    |> Enum.map(fn {dep, ver} -> "{:#{dep}, \"#{ver}\"}" end)
    |> Enum.join(",")
    |> wrap_brackets()
  end

  defp wrap_brackets(str), do: "[ #{str} ]"
end
