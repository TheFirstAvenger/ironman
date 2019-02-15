defmodule Ironman.UtilsTest do
  use ExUnit.Case

  alias Ironman.Test.Helpers.MoxHelpers
  alias Ironman.Utils

  @ironman_version Mix.Project.config()[:version]

  describe "version self check" do
    test "nothing when up to date" do
      MoxHelpers.expect_dep_http(:ironman, @ironman_version)
      assert :ok == Utils.check_self_version()
    end

    test "Upgrade when out of date" do
      MoxHelpers.expect_dep_http(:ironman, "0.0.0")
      MoxHelpers.expect_io("\nIronman is out of date. Upgrade? [Yn] ", "y")
      MoxHelpers.expect_cmd(["mix", "archive.install", "hex", "ironman", "--force"])
      assert :exit == Utils.check_self_version()
    end

    test "Dont upgrade when out of date and n pressed" do
      MoxHelpers.expect_dep_http(:ironman, "0.0.0")
      MoxHelpers.expect_io("\nIronman is out of date. Upgrade? [Yn] ", "n")
      MoxHelpers.expect_cmd("hi")
      assert :declined == Utils.check_self_version()
    end
  end

  describe "check_mix_format" do
    test "passes clean format" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"])
      assert :ok == Utils.check_mix_format()
    end

    test "exits on dirty format declined" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], :error)
      MoxHelpers.expect_io("\nYour files are not formatted. Mix Format needs to be run before continuing [Yn] ", "n")
      assert :exit = Utils.check_mix_format()
    end

    test "runs then exits on dirty format accepted format, accepted exit" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], :error)
      MoxHelpers.expect_io("\nYour files are not formatted. Mix Format needs to be run before continuing [Yn] ", "y")
      MoxHelpers.expect_cmd(["mix", "format"])

      MoxHelpers.expect_io(
        "\nMix format complete. Exit now so you can commit the formatted version before continuing [Yn] ",
        "y"
      )

      assert :exit = Utils.check_mix_format()
    end

    test "runs then ok on dirty format accepted format, decline exit" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], :error)
      MoxHelpers.expect_io("\nYour files are not formatted. Mix Format needs to be run before continuing [Yn] ", "y")
      MoxHelpers.expect_cmd(["mix", "format"])

      MoxHelpers.expect_io(
        "\nMix format complete. Exit now so you can commit the formatted version before continuing [Yn] ",
        "n"
      )

      assert :ok = Utils.check_mix_format()
    end
  end
end
