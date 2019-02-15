defmodule Ironman.Checks.DialyzerTest do
  use ExUnit.Case

  alias Ironman.Checks.DialyzerConfig
  alias Ironman.Config
  alias Ironman.Test.Helpers.{ConfigFactory, MoxHelpers}

  describe "run" do
    test "skips when dialyxir not present" do
      config = ConfigFactory.with_deps()
      {:no, config2} = DialyzerConfig.run(config)
      assert config == config2
    end

    test "skips when config present" do
      config = ConfigFactory.with_dialyzer_config()
      {:up_to_date, config2} = DialyzerConfig.run(config)
      assert config == config2
    end

    test "skips when config not present but declined by user" do
      config = ConfigFactory.with_deps(dialyxir: "~> 1.2.3")
      MoxHelpers.expect_io("\nAdd dialyzer config to project? [Yn] ", "N")
      {:no, config2} = DialyzerConfig.run(config)
      assert config == config2
    end

    test "runs when config not present - nothing else present" do
      config = ConfigFactory.with_deps(dialyxir: "~> 1.2.3")
      refute Config.get(config, :gitignore)
      refute Config.get(config, :dialyzer_ignore)
      MoxHelpers.expect_io("\nAdd dialyzer config to project? [Yn] ", "Y")
      {:yes, config2} = DialyzerConfig.run(config)
      assert "# dialyzer plt for CI caching\ntest.plt\n" = Config.get(config2, :gitignore)
      assert "[\n\n]" = Config.get(config2, :dialyzer_ignore)
    end

    test "runs when config not present - gitignore exists with end newline" do
      config = ConfigFactory.with_deps(dialyxir: "~> 1.2.3")
      config = Config.set(config, :gitignore, "existing gitignore\n\nvalues\n\n", false)
      MoxHelpers.expect_io("\nAdd dialyzer config to project? [Yn] ", "Y")
      {:yes, config2} = DialyzerConfig.run(config)
      assert "existing gitignore\n\nvalues\n\n# dialyzer plt\ntest.plt\n" = Config.get(config2, :gitignore)
    end

    test "runs when config not present - gitignore exists no end newline" do
      config = ConfigFactory.with_deps(dialyxir: "~> 1.2.3")
      config = Config.set(config, :gitignore, "existing gitignore\n\nvalues", false)
      MoxHelpers.expect_io("\nAdd dialyzer config to project? [Yn] ", "Y")
      {:yes, config2} = DialyzerConfig.run(config)
      assert "existing gitignore\n\nvalues\n\n# dialyzer plt\ntest.plt\n" = Config.get(config2, :gitignore)
    end

    test "runs when config not present - gitignore exists has plt" do
      config = ConfigFactory.with_deps(dialyxir: "~> 1.2.3")
      config = Config.set(config, :gitignore, "existing gitignore\n\nvalues\n\n# dialyzer plt\ntest.plt\n", false)
      MoxHelpers.expect_io("\nAdd dialyzer config to project? [Yn] ", "Y")
      {:yes, config2} = DialyzerConfig.run(config)
      refute Config.changed?(config2, :gitignore)
    end

    test "runs when config not present - dialyzer ignore exists" do
      config = ConfigFactory.with_deps(dialyxir: "~> 1.2.3")
      config = Config.set(config, :dialyzer_ignore, "[\"existing dialzyer filter\"]", false)
      MoxHelpers.expect_io("\nAdd dialyzer config to project? [Yn] ", "Y")
      {:yes, config2} = DialyzerConfig.run(config)
      assert "[\"existing dialzyer filter\"]" = Config.get(config2, :dialyzer_ignore)
    end
  end
end
