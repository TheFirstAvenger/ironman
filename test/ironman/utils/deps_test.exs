defmodule Ironman.Utils.DepsTest do
  use ExUnit.Case

  alias Ironman.Config
  alias Ironman.Utils.Deps

  describe "get_installed_deps/1" do
    test "returns correct deps" do
      config =
        build_config_with_mix_exs("""
        defmodule MyApp.MixProject do
          defp deps do
            [
              {:foo, "~> 1.1"},
              {:bar, "~> 2.2"}
            ]
          end
        end
        """)

      assert ["foo", "bar"] == Deps.get_installed_deps(config)
    end

    test "returns correct deps with comments" do
      config =
        build_config_with_mix_exs("""
        defmodule MyApp.MixProject do
          defp deps do
            # This is a comment
            [
              {:foo, "~> 1.1"},
              # a comment on :bar
              {:bar, "~> 2.2"}
            ]
          end
        end
        """)

      assert ["foo", "bar"] == Deps.get_installed_deps(config)
    end

    test "returns correct deps with mix new defaults" do
      config =
        build_config_with_mix_exs("""
        defmodule MyApp.MixProject do
          defp deps do
            [
              # {:dep_from_hexpm, "~> 0.3.0"},
              # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
            ]
          end
        end
        """)

      assert [] == Deps.get_installed_deps(config)
    end

    test "returns correct deps with empty deps" do
      config =
        build_config_with_mix_exs("""
        defmodule MyApp.MixProject do
          defp deps do
            []
          end
        end
        """)

      assert [] == Deps.get_installed_deps(config)
    end
  end

  describe "do_install/4" do
    test "adds correct deps with comments" do
      starting_mix = """
      defmodule MyApp.MixProject do
        defp deps do
          # This is a comment
          [
            {:foo, "~> 1.1"},
            # a comment on :bar
            {:bar, "~> 2.2"}
          ]
        end

        defp other do
          [

          ]
        end
      end
      """

      config = build_config_with_mix_exs(starting_mix)

      assert {:yes, %Config{mix_exs: new_mix}} = Deps.do_install(config, :baz, [opt1: true], "5.6.7")
      assert String.contains?(new_mix, "{:baz, \"~> 5.6.7\", opt1: true}")
      assert String.contains?(new_mix, "{:foo, \"~> 1.1\"}")
      assert String.contains?(new_mix, "{:bar, \"~> 2.2\"}")
    end

    test "adds correct deps with mix new defaults" do
      starting_mix = """
      defmodule MyApp.MixProject do
        defp deps do
          [
            # {:dep_from_hexpm, "~> 0.3.0"},
            # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
          ]
        end
      end
      """

      config = build_config_with_mix_exs(starting_mix)

      {:yes, %Config{mix_exs: new_mix}} = Deps.do_install(config, :baz, [opt1: true], "5.6.7")

      assert String.contains?(new_mix, "{:baz, \"~> 5.6.7\", opt1: true}")
    end

    test "adds dep to list with existing deps" do
      starting_mix = """
      defmodule MyApp.MixProject do
        defp deps do
          [
            {:existing, "~> 1.0"}
          ]
        end
      end
      """

      config = build_config_with_mix_exs(starting_mix)

      {:yes, %Config{mix_exs: new_mix}} = Deps.do_install(config, :new_dep, [], "2.0.0")
      assert String.contains?(new_mix, "{:new_dep, \"~> 2.0.0\"}")
      assert String.contains?(new_mix, "{:existing, \"~> 1.0\"}")
    end
  end

  defp build_config_with_mix_exs(mix_exs) do
    %Config{
      mix_exs: mix_exs
    }
  end
end
