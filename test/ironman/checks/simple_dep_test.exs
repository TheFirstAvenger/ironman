defmodule Ironman.Checks.SimpleDepTest do
  use ExUnit.Case
  alias Ironman.Checks.SimpleDep
  alias Ironman.Config
  alias Ironman.Test.Helpers.{MixBuilder, MoxHelpers}
  alias Ironman.Utils.Deps

  describe "up to date" do
    test "does nothing when dep is up to date" do
      config = MixBuilder.with_deps(ex_doc: "~> 1.2.3")

      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")

      assert {:up_to_date, ^config} = SimpleDep.run(config, :ex_doc)
    end
  end

  describe "out of date" do
    test "updates when y pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Upgrade ex_doc from ~> 1.2.2 to 1.2.3? [Yn] ", "y")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps(ex_doc: "~> 1.2.2")
      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.2\"}")
      assert {:yes, %Config{mix_exs: mix_exs} = config} = SimpleDep.run(config, :ex_doc)
      assert "~> 1.2.3" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.3\"}")
    end

    test "doesn't update when n pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Upgrade ex_doc from ~> 1.2.2 to 1.2.3? [Yn] ", "n")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps(ex_doc: "~> 1.2.2")
      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.2\"}")
      assert {:no, %Config{mix_exs: mix_exs} = config} = SimpleDep.run(config, :ex_doc)
      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.2\"}")
    end

    test "multiple" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Upgrade ex_doc from ~> 1.2.2 to 1.2.3? [Yn] ", "y")
      MoxHelpers.expect_dep_http(:earmark, "2.3.6")
      MoxHelpers.expect_io("Upgrade earmark from ~> 2.3.4 to 2.3.6? [Yn] ", "y")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps(ex_doc: "~> 1.2.2", earmark: "~> 2.3.4")

      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.2\"}")
      assert "~> 2.3.4" == Deps.get_configured_version(config, :earmark)
      assert String.contains?(mix_exs, "{:earmark, \"~> 2.3.4\"}")
      assert {:yes, %Config{mix_exs: mix_exs} = config} = SimpleDep.run(config, :ex_doc)
      assert {:yes, %Config{mix_exs: mix_exs} = config} = SimpleDep.run(config, :earmark)

      assert "~> 1.2.3" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.3\"}")
      assert "~> 2.3.6" == Deps.get_configured_version(config, :earmark)
      assert String.contains?(mix_exs, "{:earmark, \"~> 2.3.6\"}")
    end
  end

  describe "missing" do
    test "updates when y pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Install ex_doc 1.2.3? [Yn] ", "y")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps()
      assert nil == Deps.get_configured_version(config, :ex_doc)
      refute String.contains?(mix_exs, "{:ex_doc")
      assert {:yes, %Config{mix_exs: mix_exs2} = config2} = SimpleDep.run(config, :ex_doc)
      assert "~> 1.2.3" == Deps.get_configured_version(config2, :ex_doc)
      assert String.contains?(mix_exs2, "{:ex_doc, \"~> 1.2.3\"}")
    end

    test "doesn't update when n pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Install ex_doc 1.2.3? [Yn] ", "n")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps()
      assert nil == Deps.get_configured_version(config, :ex_doc)
      refute String.contains?(mix_exs, "{:ex_doc,")
      assert {:no, %Config{mix_exs: mix_exs2} = config2} = SimpleDep.run(config, :ex_doc)
      assert config == config2
      assert nil == Deps.get_configured_version(config2, :ex_doc)
      refute String.contains?(mix_exs2, "{:ex_doc,")
    end

    test "multiple" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Install ex_doc 1.2.3? [Yn] ", "y")
      MoxHelpers.expect_dep_http(:earmark, "2.3.6")
      MoxHelpers.expect_io("Install earmark 2.3.6? [Yn] ", "y")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps()

      assert nil == Deps.get_configured_version(config, :ex_doc)
      refute String.contains?(mix_exs, "{:ex_doc,")
      assert nil == Deps.get_configured_version(config, :earmark)
      refute String.contains?(mix_exs, "{:earmark,")
      assert {:yes, %Config{mix_exs: mix_exs} = config} = SimpleDep.run(config, :ex_doc)
      assert {:yes, %Config{mix_exs: mix_exs} = config} = SimpleDep.run(config, :earmark)

      assert "~> 1.2.3" == Deps.get_configured_version(config, :ex_doc)
      assert String.contains?(mix_exs, "{:ex_doc, \"~> 1.2.3\"}")
      assert "~> 2.3.6" == Deps.get_configured_version(config, :earmark)
      assert String.contains?(mix_exs, "{:earmark, \"~> 2.3.6\"}")
    end

    test "Sets dep_opts" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("Install ex_doc 1.2.3? [Yn] ", "y")

      %Config{mix_exs: mix_exs} = config = MixBuilder.with_deps()
      assert nil == Deps.get_configured_version(config, :ex_doc)
      refute String.contains?(mix_exs, "{:ex_doc")

      assert {:yes, %Config{mix_exs: mix_exs2} = config2} = SimpleDep.run(config, :ex_doc, only: :dev, runtime: false)

      assert "~> 1.2.3" == Deps.get_configured_version(config2, :ex_doc)
      assert String.contains?(mix_exs2, "{:ex_doc, \"~> 1.2.3\", only: :dev, runtime: false}")
    end
  end
end
