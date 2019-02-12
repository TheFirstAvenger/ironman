defmodule Ironman.ConfigTest do
  @moduledoc false
  use ExUnit.Case

  alias Ironman.Config
  alias Ironman.Test.Helpers.MoxHelpers

  def set_new_expectations do
    MoxHelpers.expect_file_exists?("mix.exs")
    MoxHelpers.expect_file_read!("mix.exs", "This is a mix file")
    MoxHelpers.expect_file_exists?(".gitignore")
    MoxHelpers.expect_file_read!(".gitignore", "This is a gitignore file")
    MoxHelpers.expect_file_exists?(".dialyzer_ignore.exs")
    MoxHelpers.expect_file_read!(".dialyzer_ignore.exs", "This is a dialyzer ignore file")
    MoxHelpers.raise_on_any_other()
  end

  describe "new" do
    test "populates all fields correctly" do
      set_new_expectations()
      config = Config.new!()
      assert "This is a mix file" == Config.mix_exs(config)
      assert "This is a gitignore file" == Config.gitignore(config)
      assert "This is a dialyzer ignore file" == Config.dialyzer_ignore(config)
    end
  end

  describe "mix_exs" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set_mix_exs(config, "a different value")
      assert "a different value" == Config.mix_exs(new_config)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set_mix_exs(config, "a different value")
      assert Config.gitignore(config) == Config.gitignore(new_config)
      assert Config.dialyzer_ignore(config) == Config.dialyzer_ignore(new_config)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.mix_exs_changed(config)
      new_config = Config.set_mix_exs(config, "a different value")
      assert Config.mix_exs_changed(new_config)
    end
  end

  describe "gitignore" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set_gitignore(config, "a different value")
      assert "a different value" == Config.gitignore(new_config)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set_gitignore(config, "a different value")
      assert Config.mix_exs(config) == Config.mix_exs(new_config)
      assert Config.dialyzer_ignore(config) == Config.dialyzer_ignore(new_config)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.gitignore_changed(config)
      new_config = Config.set_gitignore(config, "a different value")
      assert Config.gitignore_changed(new_config)
    end
  end

  describe "dialyzer ignore" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set_dialyzer_ignore(config, "a different value")
      assert "a different value" == Config.dialyzer_ignore(new_config)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set_dialyzer_ignore(config, "a different value")
      assert Config.mix_exs(config) == Config.mix_exs(new_config)
      assert Config.gitignore(config) == Config.gitignore(new_config)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.dialyzer_ignore_changed(config)
      new_config = Config.set_dialyzer_ignore(config, "a different value")
      assert Config.dialyzer_ignore_changed(new_config)
    end
  end
end
