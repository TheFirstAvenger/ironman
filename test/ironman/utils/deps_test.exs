defmodule Ironman.Utils.DepsTest do
  use ExUnit.Case

  alias Ironman.Config
  alias Ironman.Utils.Deps

  describe "get_installed_deps/1" do
    test "returns correct deps" do
      config =
        """
        defmodule MyApp.MixProject
          defp deps do
            [
              {:foo, "~> 1.1"},
              {:bar, "~> 2.2"}
            ]
          end
        end
        """
        |> build_config_with_mix_exs()

      assert ["foo", "bar"] == Deps.get_installed_deps(config)
    end

    test "returns correct deps with comments" do
      config =
        """
        defmodule MyApp.MixProject
          defp deps do
            # This is a comment
            [
              {:foo, "~> 1.1"},
              # a comment on :bar
              {:bar, "~> 2.2"}
            ]
          end
        end
        """
        |> build_config_with_mix_exs()

      assert ["foo", "bar"] == Deps.get_installed_deps(config)
    end

    test "returns correct deps with mix new defaults" do
      config =
        """
        defmodule MyApp.MixProject
          defp deps do
            [
              # {:dep_from_hexpm, "~> 0.3.0"},
              # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
            ]
          end
        end
        """
        |> build_config_with_mix_exs()

      assert [] == Deps.get_installed_deps(config)
    end

    test "returns correct deps with empty deps" do
      config =
        """
        defmodule MyApp.MixProject
          defp deps do
            []
          end
        end
        """
        |> build_config_with_mix_exs()

      assert [] == Deps.get_installed_deps(config)
    end
  end

  describe "remove_comments/1" do
    test "removes comments" do
      start = """
      defmodule MyApp.MixProject
        defp deps do
          # This is a comment
          [
            # {:dep_from_hexpm, "~> 0.3.0"},
            # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
          ]
        end
      end
      """

      expected = """
      defmodule MyApp.MixProject
        defp deps do
          [
          ]
        end
      end
      """

      assert Deps.remove_comments(start) == expected
    end
  end

  describe "do_install/4" do
    test "adds correct deps with comments" do
      starting_mix = """
      defmodule MyApp.MixProject
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

      expected_mix = """
      defmodule MyApp.MixProject
        defp deps do
          [{:baz, "~> 5.6.7", opt1: true},
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
      assert new_mix == expected_mix
    end

    test "adds correct deps with mix new defaults" do
      starting_mix = """
      defmodule MyApp.MixProject
        defp deps do
          [
            # {:dep_from_hexpm, "~> 0.3.0"},
            # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
          ]
        end
      end
      """

      expected_mix = """
      defmodule MyApp.MixProject
        defp deps do
          [{:baz, "~> 5.6.7", opt1: true},
            # {:dep_from_hexpm, "~> 0.3.0"},
            # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
          ]
        end
      end
      """

      config = build_config_with_mix_exs(starting_mix)

      assert {:yes, %Config{mix_exs: new_mix}} = Deps.do_install(config, :baz, [opt1: true], "5.6.7")
      assert new_mix == expected_mix
    end
  end

  defp build_config_with_mix_exs(mix_exs) do
    %Config{
      mix_exs: mix_exs
    }
  end
end
