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

    test "skips when config present" do
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
      refute Config.get(config, :starting_project_config)[:preferred_cli_env]
      refute Config.get(config, :coveralls_json)
      MoxHelpers.expect_io("\nAdd coveralls config to project? [Yn] ", "Y")
      {:yes, config2} = CoverallsConfig.run(config)
      assert String.contains?(Config.get(config2, :mix_exs), "test_coverage: [tool: ExCoveralls]")

      assert String.contains?(
               Config.get(config2, :mix_exs),
               ~s(preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test])
             )

      assert Config.get(config2, :coveralls_json) == "{\n  \"skip_files\": []\n}"
    end

    test "runs when config not present but coveralls.json present" do
      config =
        [excoveralls: "~> 1.2.3"]
        |> ConfigFactory.with_deps()
        |> Config.set(:coveralls_json, "existing coveralls config")

      refute Config.get(config, :starting_project_config)[:test_coverage]
      refute Config.get(config, :starting_project_config)[:preferred_cli_env]
      assert Config.get(config, :coveralls_json) == "existing coveralls config"
      MoxHelpers.expect_io("\nAdd coveralls config to project? [Yn] ", "Y")
      {:yes, config2} = CoverallsConfig.run(config)
      assert String.contains?(Config.get(config2, :mix_exs), "test_coverage: [tool: ExCoveralls]")

      assert String.contains?(
               Config.get(config2, :mix_exs),
               ~s(preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test])
             )

      assert Config.get(config2, :coveralls_json) == "existing coveralls config"
    end
  end
end
