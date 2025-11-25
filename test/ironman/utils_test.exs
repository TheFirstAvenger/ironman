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
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], {:error, 1})

      MoxHelpers.expect_io(
        "\nYour code is not formatted. Ironman will modify your code and may change formatting.\nRun mix format now? [Yn] ",
        "n"
      )

      assert :exit = Utils.check_mix_format()
    end

    test "runs format then offers commit when git repo exists" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], {:error, 1})

      MoxHelpers.expect_io(
        "\nYour code is not formatted. Ironman will modify your code and may change formatting.\nRun mix format now? [Yn] ",
        "y"
      )

      MoxHelpers.expect_cmd(["mix", "format"])
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:ok, ".git"})
      MoxHelpers.expect_io("\nMix format complete. Commit the formatting changes? [Yn] ", "y")
      MoxHelpers.expect_cmd(["git", "add", "-A"])
      MoxHelpers.expect_cmd(["git", "commit", "-m", "Run mix format"])

      assert :ok = Utils.check_mix_format()
    end

    test "runs format and skips commit when declined" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], {:error, 1})

      MoxHelpers.expect_io(
        "\nYour code is not formatted. Ironman will modify your code and may change formatting.\nRun mix format now? [Yn] ",
        "y"
      )

      MoxHelpers.expect_cmd(["mix", "format"])
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:ok, ".git"})
      MoxHelpers.expect_io("\nMix format complete. Commit the formatting changes? [Yn] ", "n")

      assert :ok = Utils.check_mix_format()
    end

    test "runs format without commit offer when no git repo" do
      MoxHelpers.expect_cmd(["mix", "format", "--check-formatted"], {:error, 1})

      MoxHelpers.expect_io(
        "\nYour code is not formatted. Ironman will modify your code and may change formatting.\nRun mix format now? [Yn] ",
        "y"
      )

      MoxHelpers.expect_cmd(["mix", "format"])
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:error, 1})

      assert :ok = Utils.check_mix_format()
    end
  end

  describe "check_git_repo" do
    test "returns ok when git repo exists" do
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:ok, ".git"})
      assert :ok == Utils.check_git_repo()
    end

    test "offers to init git repo when none exists" do
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:error, 1})
      MoxHelpers.expect_io("\nNo git repository found. Initialize one now? [Yn] ", "y")
      MoxHelpers.expect_cmd(["git", "init"])
      MoxHelpers.expect_io("\nCreate initial commit with all current files? [Yn] ", "y")
      MoxHelpers.expect_cmd(["git", "add", "-A"])
      MoxHelpers.expect_cmd(["git", "commit", "-m", "Initial commit"])

      assert :ok == Utils.check_git_repo()
    end

    test "skips git init when declined" do
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:error, 1})
      MoxHelpers.expect_io("\nNo git repository found. Initialize one now? [Yn] ", "n")

      assert :ok == Utils.check_git_repo()
    end

    test "skips initial commit when declined" do
      MoxHelpers.expect_cmd(["git", "rev-parse", "--git-dir"], {:error, 1})
      MoxHelpers.expect_io("\nNo git repository found. Initialize one now? [Yn] ", "y")
      MoxHelpers.expect_cmd(["git", "init"])
      MoxHelpers.expect_io("\nCreate initial commit with all current files? [Yn] ", "n")

      assert :ok == Utils.check_git_repo()
    end
  end
end
