defmodule Ironman.Checks.DialyzerTest do
  use ExUnit.Case

  alias Ironman.Checks.DialyzerConfig
  alias Ironman.Config
  alias Ironman.Test.Helpers.{MixBuilder, MoxHelpers}

  describe "run" do
    test "skips when config present" do
      config = MixBuilder.with_dialyzer()
      {:up_to_date, config2} = DialyzerConfig.run(config)
      assert config == config2
    end

    test "skips when config not present but declined by user" do
      config = MixBuilder.with_deps(dialyzer: "~> 1.2.3")
      MoxHelpers.expect_io("Add dialyzer config to project? [Yn] ", "N")
      MoxHelpers.raise_on_io()
      {:no, config2} = DialyzerConfig.run(config)
      assert config == config2
    end

    test "runs when config not present - nothing else present" do
      config = MixBuilder.with_deps(dialyzer: "~> 1.2.3")
      refute Config.gitignore(config)
      refute Config.dialyzer_ignore(config)
      MoxHelpers.expect_io("Add dialyzer config to project? [Yn] ", "Y")
      MoxHelpers.raise_on_any_other()
      {:yes, config2} = DialyzerConfig.run(config)
      assert "# dialyzer plt for CI caching\ntest.plt\n" = Config.gitignore(config2)
      assert "[\n\n]" = Config.dialyzer_ignore(config2)
    end

    test "runs when config not present - gitignore exists with end newline" do
      config = MixBuilder.with_deps(dialyzer: "~> 1.2.3")
      config = Config.set_gitignore(config, "existing gitignore\n\nvalues\n\n")
      MoxHelpers.expect_io("Add dialyzer config to project? [Yn] ", "Y")
      MoxHelpers.raise_on_any_other()
      {:yes, config2} = DialyzerConfig.run(config)
      assert "existing gitignore\n\nvalues\n\n# dialyzer plt\ntest.plt\n" = Config.gitignore(config2)
    end

    test "runs when config not present - gitignore exists no end newline" do
      config = MixBuilder.with_deps(dialyzer: "~> 1.2.3")
      config = Config.set_gitignore(config, "existing gitignore\n\nvalues")
      MoxHelpers.expect_io("Add dialyzer config to project? [Yn] ", "Y")
      MoxHelpers.raise_on_any_other()
      {:yes, config2} = DialyzerConfig.run(config)
      assert "existing gitignore\n\nvalues\n\n# dialyzer plt\ntest.plt\n" = Config.gitignore(config2)
    end

    test "runs when config not present - dialyzer ignore exists" do
      config = MixBuilder.with_deps(dialyzer: "~> 1.2.3")
      config = Config.set_dialyzer_ignore(config, "[\"existing dialzyer filter\"]")
      MoxHelpers.expect_io("Add dialyzer config to project? [Yn] ", "Y")
      MoxHelpers.raise_on_any_other()
      {:yes, config2} = DialyzerConfig.run(config)
      assert "[\"existing dialzyer filter\"]" = Config.dialyzer_ignore(config2)
    end
  end
end
