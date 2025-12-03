defmodule Ironman.Test.Helpers.ConfigFactory do
  @moduledoc false
  alias Ironman.Config

  def empty do
    Config.new(mix_exs: "", config_exs: "")
  end

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

    [starting_project_config: [app: :test]]
    |> Config.new()
    |> Config.set(:mix_exs, mix_exs, false)
    |> Config.set(:config_exs, "import Config\n\n", false)
  end

  def with_dialyzer_config do
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
        [
          {:dialyxir, "~> 1.2.3"}
        ]
      end
    end
    """

    [starting_project_config: [dialyzer: [:asdf]]]
    |> Config.new()
    |> Config.set(:mix_exs, mix_exs, false)
  end

  def with_coveralls_config do
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
        test_coverage: [tool: ExCoveralls]
      ]
      end

      def cli do
        [
          preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
        ]
      end

      # Run "mix help deps" to learn about dependencies.
      defp deps do
        [
          {:excoveralls, "~> 1.2.3"}
        ]
      end
    end
    """

    [
      starting_project_config: [
        test_coverage: [tool: ExCoveralls]
      ]
    ]
    |> Config.new()
    |> Config.set(:mix_exs, mix_exs, false)
  end

  def with_git_hooks_config do
    [git_hooks: "1.2.3"]
    |> with_deps()
    |> Config.set(:config_dev_exs, "import Config\n\nconfig :git_hooks,", false)
  end

  @spec mix_string(list()) :: String.t()
  def mix_string(deps) do
    deps
    |> Enum.map_join(",\n", fn {dep, ver} -> "      {:#{dep}, \"#{ver}\"}" end)
    |> wrap_brackets()
  end

  defp wrap_brackets(""), do: "[]"
  defp wrap_brackets(str), do: "[\n#{str}\n    ]"
end
