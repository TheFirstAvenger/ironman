defmodule Ironman.Checks.CredoConfigTest do
  use ExUnit.Case

  alias Ironman.Checks.CredoConfig
  alias Ironman.Config
  alias Ironman.Test.Helpers.{ConfigFactory, MoxHelpers}

  describe "run" do
    test "skips when credo not present" do
      config = ConfigFactory.with_deps()
      {:skip, config2} = CredoConfig.run(config)
      assert MapSet.size(config2.changed) == 0
      assert config == config2
    end

    test "skips when config present" do
      config = ConfigFactory.with_deps(credo: "~ 1.2.3")
      config = Config.set(config, :credo_exs, "This is a credo config", false)
      {:up_to_date, config2} = CredoConfig.run(config)
      assert MapSet.size(config2.changed) == 0
      assert config == config2
    end

    test "skips when config not present but declined by user" do
      config = ConfigFactory.with_deps(credo: "~> 1.2.3")
      MoxHelpers.expect_io("\nAdd credo config to project? [Yn] ", "N")
      {:no, config2} = CredoConfig.run(config)
      assert MapSet.size(config2.changed) == 0
      assert config == config2
    end

    test "runs when config not present" do
      config = ConfigFactory.with_deps(credo: "~> 1.2.3")
      refute Config.get(config, :credo_exs)
      MoxHelpers.expect_io("\nAdd credo config to project? [Yn] ", "Y")
      {:yes, config2} = CredoConfig.run(config)
      new_config = Config.get(config2, :credo_exs)
      assert MapSet.size(config2.changed) == 1
      assert String.contains?(new_config, "This file contains the configuration for Credo")
    end
  end
end
