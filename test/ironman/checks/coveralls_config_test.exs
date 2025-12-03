defmodule Ironman.Checks.CoverallsConfigTest do
  use ExUnit.Case

  alias Ironman.Checks.CoverallsConfig
  alias Ironman.Config
  alias Ironman.Test.Helpers.ConfigFactory
  alias Ironman.Test.Helpers.MoxHelpers

  describe "run" do
    test "skips when coveralls not present" do
      config = ConfigFactory.with_deps()
      {:skip, config2} = CoverallsConfig.run(config)
      assert config == config2
    end

    test "skips when config present with def cli" do
      config = ConfigFactory.with_coveralls_config()
      {:up_to_date, config2} = CoverallsConfig.run(config)
      assert config == config2
    end

    test "skips when config not present but declined by user" do
      config = ConfigFactory.with_deps(excoveralls: "~> 1.2.3")
      MoxHelpers.expect_io("\nAdd coveralls config to project? [Yn] ", "N")
      {:no, config2} = CoverallsConfig.run(config)
      assert config == config2
    end

    test "runs when config not present" do
      config = ConfigFactory.with_deps(excoveralls: "~> 1.2.3")
      refute Config.get(config, :starting_project_config)[:test_coverage]
      refute Config.get(config, :coveralls_json)
      MoxHelpers.expect_io("\nAdd coveralls config to project? [Yn] ", "Y")
      {:yes, config2} = CoverallsConfig.run(config)
      mix_exs = Config.get(config2, :mix_exs)

      # test_coverage should be in def project
      assert String.contains?(mix_exs, "test_coverage: [tool: ExCoveralls]")

      # preferred_envs should be in def cli (not preferred_cli_env in project)
      assert String.contains?(mix_exs, "def cli do")

      assert String.contains?(
               mix_exs,
               ~s(preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test])
             )

      # Should NOT have deprecated preferred_cli_env in project
      refute String.contains?(mix_exs, "preferred_cli_env:")

      assert Config.get(config2, :coveralls_json) == "{\n  \"skip_files\": []\n}"
    end

    test "runs when config not present but coveralls.json present" do
      config =
        [excoveralls: "~> 1.2.3"]
        |> ConfigFactory.with_deps()
        |> Config.set(:coveralls_json, "existing coveralls config")

      refute Config.get(config, :starting_project_config)[:test_coverage]
      assert Config.get(config, :coveralls_json) == "existing coveralls config"
      MoxHelpers.expect_io("\nAdd coveralls config to project? [Yn] ", "Y")
      {:yes, config2} = CoverallsConfig.run(config)
      mix_exs = Config.get(config2, :mix_exs)

      assert String.contains?(mix_exs, "test_coverage: [tool: ExCoveralls]")
      assert String.contains?(mix_exs, "def cli do")

      assert String.contains?(
               mix_exs,
               ~s(preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test])
             )

      assert Config.get(config2, :coveralls_json) == "existing coveralls config"
    end
  end
end
