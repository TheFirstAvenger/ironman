defmodule Ironman.Test.Helpers.MixBuilder do
  @moduledoc false
  alias Ironman.Config

  def with_deps(deps \\ []) when is_list(deps) do
    mix_exs = """
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

    %Config{starting_project_config: [app: :test]}
    |> Config.set_mix_exs(mix_exs)
  end

  def with_dialyzer do
    mix_exs = """
    defmodule Test.MixProject do
      use Mix.Project

      def project do
      [
        app: :test,
        version: "0.1.0",
        elixir: "~> 1.8",
        start_permanent: Mix.env() == :prod,
        deps: deps(),
        dialyzer: [
          ignore_warnings: ".dialyzer_ignore.exs",
          list_unused_filters: true,
          plt_file: {:no_warn, "test.plt"}
        ]
      ]
      end

      # Run "mix help deps" to learn about dependencies.
      defp deps do
        []
      end
    end
    """

    %Config{starting_project_config: [dialyzer: [:asdf]]}
    |> Config.set_mix_exs(mix_exs)
  end

  @spec mix_string(list()) :: String.t()
  def mix_string(deps) do
    deps
    |> Enum.map(fn {dep, ver} -> "      {:#{dep}, \"#{ver}\"}" end)
    |> Enum.join(",\n")
    |> wrap_brackets()
  end

  defp wrap_brackets(""), do: "[]"
  defp wrap_brackets(str), do: "[\n#{str}\n    ]"
end
