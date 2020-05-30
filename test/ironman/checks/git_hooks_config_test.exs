defmodule Ironman.Checks.GitHooksConfigTest do
  use ExUnit.Case

  alias Ironman.Checks.GitHooksConfig
  alias Ironman.Config
  alias Ironman.Test.Helpers.{ConfigFactory, MoxHelpers}

  describe "run" do
    test "skips when git_hooks not present" do
      config = ConfigFactory.with_deps()
      {:skip, config2} = GitHooksConfig.run(config)
      assert config == config2
    end

    test "skips when config present" do
      config = ConfigFactory.with_git_hooks_config()
      {:up_to_date, config2} = GitHooksConfig.run(config)
      assert config == config2
    end

    test "skips when config not present but declined by user" do
      config = ConfigFactory.with_deps(git_hooks: "~> 1.2.3")
      MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "N")
      {:no, config2} = GitHooksConfig.run(config)
      assert config == config2
    end

    test "runs when config not present - nothing else present" do
      config = ConfigFactory.with_deps(git_hooks: "~> 1.2.3")
      refute Config.get(config, :config_dev_exs)
      refute Config.get(config, :config_test_exs)
      refute Config.get(config, :config_prod_exs)
      MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "Y")
      {:yes, config2} = GitHooksConfig.run(config)
      assert "use Mix.Config\n\n" = Config.get(config2, :config_exs)
      assert String.starts_with?(Config.get(config2, :config_dev_exs), "use Mix.Config\n\nconfig :git_hooks,")
      refute String.contains?(Config.get(config2, :config_dev_exs), "credo --strict")
      refute String.contains?(Config.get(config2, :config_dev_exs), "dialyzer --halt-exit-status")
      assert "use Mix.Config\n\n" = Config.get(config2, :config_test_exs)
      assert "use Mix.Config\n\n" = Config.get(config2, :config_prod_exs)
    end

    test "runs when config not present - config import commented out" do
      config =
        ConfigFactory.with_deps(git_hooks: "~> 1.2.3")
        |> Config.set(:config_exs, "use Mix.Config\n\n#\n#\n#     import_config \"\#{Mix.env\(\)}.exs\"\n")

      MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "Y")
      {:yes, config2} = GitHooksConfig.run(config)
      assert "use Mix.Config\n\n#\n#\nimport_config \"\#{Mix.env()}.exs\"\n" = Config.get(config2, :config_exs)
    end

    test "runs when config not present - *.exs present" do
      config =
        ConfigFactory.with_deps(git_hooks: "~> 1.2.3")
        |> Config.set(:config_dev_exs, "use Mix.Config\n\n")
        |> Config.set(:config_test_exs, "use Mix.Config\n\n")
        |> Config.set(:config_prod_exs, "use Mix.Config\n\n")

      MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "Y")
      {:yes, config2} = GitHooksConfig.run(config)
      assert "use Mix.Config\n\n" = Config.get(config2, :config_exs)
      assert String.starts_with?(Config.get(config2, :config_dev_exs), "use Mix.Config\n\n\n\nconfig :git_hooks,")
      refute String.contains?(Config.get(config2, :config_dev_exs), "credo --strict")
      refute String.contains?(Config.get(config2, :config_dev_exs), "dialyzer")
      assert "use Mix.Config\n\n" = Config.get(config2, :config_test_exs)
      assert "use Mix.Config\n\n" = Config.get(config2, :config_prod_exs)
    end

    test "runs when config not present - config directory not present" do
      config =
        ConfigFactory.with_deps(git_hooks: "~> 1.2.3")
        |> Config.set(:config_exs, nil)
        |> Config.set(:config_dev_exs, "use Mix.Config\n\n")
        |> Config.set(:config_test_exs, "use Mix.Config\n\n")
        |> Config.set(:config_prod_exs, "use Mix.Config\n\n")

      MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "Y")
      MoxHelpers.expect_directory_create("config")
      MoxHelpers.expect_file_touch!("config/config.exs")

      {:yes, config2} = GitHooksConfig.run(config)
      assert "use Mix.Config\n\nimport_config \"\#{Mix.env()}.exs\"\n" = Config.get(config2, :config_exs)
      assert String.starts_with?(Config.get(config2, :config_dev_exs), "use Mix.Config\n\n\n\nconfig :git_hooks,")
      refute String.contains?(Config.get(config2, :config_dev_exs), "credo --strict")
      refute String.contains?(Config.get(config2, :config_dev_exs), "dialyzer")
      assert "use Mix.Config\n\n" = Config.get(config2, :config_test_exs)
      assert "use Mix.Config\n\n" = Config.get(config2, :config_prod_exs)
    end
  end

  test "includes credo line when credo dep exists" do
    config = ConfigFactory.with_deps(git_hooks: "~> 1.2.3", credo: "~> 1.2.3")
    refute Config.get(config, :config_dev_exs)
    refute Config.get(config, :config_test_exs)
    refute Config.get(config, :config_prod_exs)
    MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "Y")
    {:yes, config2} = GitHooksConfig.run(config)
    assert "use Mix.Config\n\n" = Config.get(config2, :config_exs)
    assert String.starts_with?(Config.get(config2, :config_dev_exs), "use Mix.Config\n\nconfig :git_hooks,")
    assert String.contains?(Config.get(config2, :config_dev_exs), "credo --strict")
    refute String.contains?(Config.get(config2, :config_dev_exs), "dialyzer")
    assert "use Mix.Config\n\n" = Config.get(config2, :config_test_exs)
    assert "use Mix.Config\n\n" = Config.get(config2, :config_prod_exs)
  end

  test "includes dialyzer line when dialyxir dep exists" do
    config = ConfigFactory.with_deps(git_hooks: "~> 1.2.3", dialyxir: "~> 1.2.3")
    refute Config.get(config, :config_dev_exs)
    refute Config.get(config, :config_test_exs)
    refute Config.get(config, :config_prod_exs)
    MoxHelpers.expect_io("\nAdd git_hooks config to project? [Yn] ", "Y")
    {:yes, config2} = GitHooksConfig.run(config)
    assert "use Mix.Config\n\n" = Config.get(config2, :config_exs)
    assert String.starts_with?(Config.get(config2, :config_dev_exs), "use Mix.Config\n\nconfig :git_hooks,")
    refute String.contains?(Config.get(config2, :config_dev_exs), "credo --strict")
    assert String.contains?(Config.get(config2, :config_dev_exs), "dialyzer")
    assert "use Mix.Config\n\n" = Config.get(config2, :config_test_exs)
    assert "use Mix.Config\n\n" = Config.get(config2, :config_prod_exs)
  end
end
