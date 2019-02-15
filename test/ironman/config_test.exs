defmodule Ironman.ConfigTest do
  @moduledoc false
  use ExUnit.Case

  alias Ironman.Config
  alias Ironman.Test.Helpers.MoxHelpers

  @all_fields Map.keys(%Config{})

  def set_new_expectations do
    MoxHelpers.expect_file_exists?("mix.exs")
    MoxHelpers.expect_file_read!("mix.exs", "This is a mix file")
    MoxHelpers.expect_file_exists?("config/config.exs")
    MoxHelpers.expect_file_read!("config/config.exs", "This is a config exs file")
    MoxHelpers.expect_file_exists?("config/dev.exs")
    MoxHelpers.expect_file_read!("config/dev.exs", "This is a config dev exs file")
    MoxHelpers.expect_file_exists?("config/test.exs")
    MoxHelpers.expect_file_read!("config/test.exs", "This is a config test exs file")
    MoxHelpers.expect_file_exists?("config/prod.exs")
    MoxHelpers.expect_file_read!("config/prod.exs", "This is a config prod exs file")
    MoxHelpers.expect_file_exists?(".gitignore")
    MoxHelpers.expect_file_read!(".gitignore", "This is a gitignore file")
    MoxHelpers.expect_file_exists?(".dialyzer_ignore.exs")
    MoxHelpers.expect_file_read!(".dialyzer_ignore.exs", "This is a dialyzer ignore file")
  end

  defp all_fields_equal_except(config1, config2, field) do
    @all_fields
    |> List.delete(field)
    |> List.delete(:changed)
    |> Enum.each(fn field ->
      assert Config.get(config1, field) == Config.get(config2, field)
    end)
  end

  describe "new" do
    test "populates all fields correctly" do
      set_new_expectations()
      config = Config.new!()
      assert "This is a mix file" == Config.get(config, :mix_exs)
      assert "This is a gitignore file" == Config.get(config, :gitignore)
      assert "This is a dialyzer ignore file" == Config.get(config, :dialyzer_ignore)
      assert "This is a config exs file" == Config.get(config, :config_exs)
      assert "This is a config dev exs file" == Config.get(config, :config_dev_exs)
      assert "This is a config prod exs file" == Config.get(config, :config_prod_exs)
      assert "This is a config test exs file" == Config.get(config, :config_test_exs)
    end
  end

  describe "mix_exs" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :mix_exs, "a different value")
      assert "a different value" == Config.get(new_config, :mix_exs)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :mix_exs, "a different value")
      all_fields_equal_except(config, new_config, :mix_exs)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :mix_exs)
      new_config = Config.set(config, :mix_exs, "a different value")
      assert Config.changed?(new_config, :mix_exs)
    end
  end

  describe "gitignore" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :gitignore, "a different value")
      assert "a different value" == Config.get(new_config, :gitignore)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :gitignore, "a different value")
      all_fields_equal_except(config, new_config, :gitignore)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :gitignore)
      new_config = Config.set(config, :gitignore, "a different value")
      assert Config.changed?(new_config, :gitignore)
    end
  end

  describe "dialyzer ignore" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :dialyzer_ignore, "a different value")
      assert "a different value" == Config.get(new_config, :dialyzer_ignore)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :dialyzer_ignore, "a different value")
      all_fields_equal_except(config, new_config, :dialyzer_ignore)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :dialyzer_ignore)
      new_config = Config.set(config, :dialyzer_ignore, "a different value")
      assert Config.changed?(new_config, :dialyzer_ignore)
    end
  end

  describe "config_exs" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_exs, "a different value")
      assert "a different value" == Config.get(new_config, :config_exs)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_exs, "a different value")
      all_fields_equal_except(config, new_config, :config_exs)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :config_exs)
      new_config = Config.set(config, :config_exs, "a different value")
      assert Config.changed?(new_config, :config_exs)
    end
  end

  describe "config_dev_exs" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_dev_exs, "a different value")
      assert "a different value" == Config.get(new_config, :config_dev_exs)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_dev_exs, "a different value")
      all_fields_equal_except(config, new_config, :config_dev_exs)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :config_dev_exs)
      new_config = Config.set(config, :config_dev_exs, "a different value")
      assert Config.changed?(new_config, :config_dev_exs)
    end
  end

  describe "config_test_exs" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_test_exs, "a different value")
      assert "a different value" == Config.get(new_config, :config_test_exs)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_test_exs, "a different value")
      all_fields_equal_except(config, new_config, :config_test_exs)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :config_test_exs)
      new_config = Config.set(config, :config_test_exs, "a different value")
      assert Config.changed?(new_config, :config_test_exs)
    end
  end

  describe "config_prod_exs" do
    test "set updates field" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_prod_exs, "a different value")
      assert "a different value" == Config.get(new_config, :config_prod_exs)
    end

    test "set doesn't change other fields" do
      set_new_expectations()
      config = Config.new!()
      new_config = Config.set(config, :config_prod_exs, "a different value")
      all_fields_equal_except(config, new_config, :config_prod_exs)
    end

    test "set updates changed flag" do
      set_new_expectations()
      config = Config.new!()
      refute Config.changed?(config, :config_prod_exs)
      new_config = Config.set(config, :config_prod_exs, "a different value")
      assert Config.changed?(new_config, :config_prod_exs)
    end
  end
end
