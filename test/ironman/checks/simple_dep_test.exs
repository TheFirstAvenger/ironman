defmodule Ironman.Checks.SimpleDepTest do
  use ExUnit.Case
  alias Ironman.Checks.SimpleDep
  alias Ironman.Config
  alias Ironman.Test.Helpers.{ConfigFactory, MoxHelpers}
  alias Ironman.Utils.Deps

  describe "up to date" do
    test "does nothing when dep is up to date" do
      config = ConfigFactory.with_deps(ex_doc: "~> 1.2.3")

      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")

      assert {:up_to_date, ^config} = SimpleDep.run(config, :ex_doc)
    end
  end

  describe "out of date" do
    test "updates when y pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nUpgrade ex_doc from ~> 1.2.2 to 1.2.3? [Yn] ", "y")

      %Config{} = config = ConfigFactory.with_deps(ex_doc: "~> 1.2.2")
      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert {:yes, %Config{} = config} = SimpleDep.run(config, :ex_doc)
      assert "~> 1.2.3" == Deps.get_configured_version(config, :ex_doc)
    end

    test "doesn't update when n pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nUpgrade ex_doc from ~> 1.2.2 to 1.2.3? [Yn] ", "n")

      %Config{} = config = ConfigFactory.with_deps(ex_doc: "~> 1.2.2")
      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert {:no, %Config{} = config} = SimpleDep.run(config, :ex_doc)
      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
    end

    test "multiple" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nUpgrade ex_doc from ~> 1.2.2 to 1.2.3? [Yn] ", "y")
      MoxHelpers.expect_dep_http(:credo, "2.3.6")
      MoxHelpers.expect_io("\nUpgrade credo from ~> 2.3.4 to 2.3.6? [Yn] ", "y")

      %Config{} = config = ConfigFactory.with_deps(ex_doc: "~> 1.2.2", credo: "~> 2.3.4")

      assert "~> 1.2.2" == Deps.get_configured_version(config, :ex_doc)
      assert "~> 2.3.4" == Deps.get_configured_version(config, :credo)
      assert {:yes, %Config{} = config} = SimpleDep.run(config, :ex_doc)
      assert {:yes, %Config{} = config} = SimpleDep.run(config, :credo)

      assert "~> 1.2.3" == Deps.get_configured_version(config, :ex_doc)
      assert "~> 2.3.6" == Deps.get_configured_version(config, :credo)
    end
  end

  describe "missing" do
    test "updates when y pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nInstall ex_doc 1.2.3? [Yn] ", "y")

      %Config{} = config = ConfigFactory.with_deps()
      assert nil == Deps.get_configured_version(config, :ex_doc)
      assert {:yes, %Config{} = config2} = SimpleDep.run(config, :ex_doc)
      assert "~> 1.2.3" == Deps.get_configured_version(config2, :ex_doc)
    end

    test "doesn't update when n pressed" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nInstall ex_doc 1.2.3? [Yn] ", "n")

      %Config{} = config = ConfigFactory.with_deps()
      assert nil == Deps.get_configured_version(config, :ex_doc)
      assert {:no, %Config{} = config2} = SimpleDep.run(config, :ex_doc)
      assert config == config2
      assert nil == Deps.get_configured_version(config2, :ex_doc)
    end

    test "multiple" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nInstall ex_doc 1.2.3? [Yn] ", "y")
      MoxHelpers.expect_dep_http(:credo, "2.3.6")
      MoxHelpers.expect_io("\nInstall credo 2.3.6? [Yn] ", "y")

      %Config{} = config = ConfigFactory.with_deps()

      assert nil == Deps.get_configured_version(config, :ex_doc)
      assert nil == Deps.get_configured_version(config, :credo)
      assert {:yes, %Config{} = config} = SimpleDep.run(config, :ex_doc)
      assert {:yes, %Config{} = config} = SimpleDep.run(config, :credo)

      assert "~> 1.2.3" == Deps.get_configured_version(config, :ex_doc)
      assert "~> 2.3.6" == Deps.get_configured_version(config, :credo)
    end

    test "Sets dep_opts" do
      MoxHelpers.expect_dep_http(:ex_doc, "1.2.3")
      MoxHelpers.expect_io("\nInstall ex_doc 1.2.3? [Yn] ", "y")

      %Config{} = config = ConfigFactory.with_deps()
      assert nil == Deps.get_configured_version(config, :ex_doc)

      assert {:yes, %Config{} = config2} = SimpleDep.run(config, :ex_doc, only: :dev, runtime: false)

      assert [only: :dev, runtime: false] == Deps.get_configured_opts(config2, :ex_doc)
    end
  end
end
