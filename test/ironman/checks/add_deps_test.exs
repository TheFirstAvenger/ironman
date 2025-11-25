defmodule Ironman.Checks.AddDepsTest do
  use ExUnit.Case

  alias Ironman.Checks.AddDeps
  alias Ironman.Test.Helpers.ConfigFactory
  alias Ironman.Test.Helpers.MoxHelpers
  alias Ironman.Utils.Deps

  describe "run" do
    test "does nothing when user declines" do
      config = ConfigFactory.empty()
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")
      assert {:no, ^config} = AddDeps.run(config)
    end

    test "does nothing when user accepts but then gives empty string" do
      config = ConfigFactory.empty()
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")

      assert {:no, ^config} = AddDeps.run(config)
    end

    test "does nothing when user gives nonexistent dep" do
      config = ConfigFactory.empty()
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "foo_bar")
      MoxHelpers.expect_dep_http_not_found(:foo_bar)
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")

      assert {:no, ^config} = AddDeps.run(config)
    end

    test "does nothing when user gives up to date dep" do
      config = ConfigFactory.with_deps(foo_bar: "~> 1.2.3")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "foo_bar")
      MoxHelpers.expect_dep_http(:foo_bar, "1.2.3")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")

      assert {:no, ^config} = AddDeps.run(config)
    end

    test "does nothing when user gives existing outdated dep but declines" do
      config = ConfigFactory.with_deps(foo_bar: "~> 1.2.3")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "foo_bar")
      MoxHelpers.expect_dep_http(:foo_bar, "1.2.4")
      MoxHelpers.expect_io("\nUpgrade foo_bar from ~> 1.2.3 to 1.2.4? [Yn] ", "n")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")
      config = %{config | skipped_upgrades: MapSet.new([:foo_bar])}
      assert {:no, ^config} = AddDeps.run(config)
    end

    test "updates when user gives existing outdated dep" do
      config = ConfigFactory.with_deps(foo_bar: "~> 1.2.3")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "foo_bar")
      MoxHelpers.expect_dep_http(:foo_bar, "1.2.4")
      MoxHelpers.expect_io("\nUpgrade foo_bar from ~> 1.2.3 to 1.2.4? [Yn] ", "y")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")

      assert {:yes, new_config} = AddDeps.run(config)
      assert Deps.get_configured_version(new_config, :foo_bar) == "~> 1.2.4"
    end

    test "does nothing when user gives new dep but declines" do
      config = ConfigFactory.with_deps()
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "foo_bar")
      MoxHelpers.expect_dep_http(:foo_bar, "1.2.4")
      MoxHelpers.expect_io("\nInstall foo_bar 1.2.4? [Yn] ", "n")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")

      assert {:no, ^config} = AddDeps.run(config)
    end

    test "updates when user gives new dep" do
      config = ConfigFactory.with_deps()
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "y")
      MoxHelpers.expect_io("What dependency? (e.g. ets)\n", "foo_bar")
      MoxHelpers.expect_dep_http(:foo_bar, "1.2.4")
      MoxHelpers.expect_io("\nInstall foo_bar 1.2.4? [Yn] ", "y")
      MoxHelpers.expect_io("\nInstall any other dependencies? [Yn] ", "n")

      assert {:yes, new_config} = AddDeps.run(config)
      assert Deps.get_configured_version(new_config, :foo_bar) == "~> 1.2.4"
    end
  end
end
