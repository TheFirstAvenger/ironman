defmodule Ironman.Runner do
  @moduledoc false
  alias Ironman.Checks.{AddDeps, CoverallsConfig, CredoConfig, DialyzerConfig, GitHooksConfig, SimpleDep, UpdateAllDeps}
  alias Ironman.{Config, Utils}

  @checks [
    :ex_doc,
    :earmark,
    :dialyxir,
    :mix_test_watch,
    :credo,
    :excoveralls,
    :git_hooks,
    :dialyzer_config,
    :git_hooks_config,
    :coveralls_config,
    :credo_exs,
    :update_all_deps,
    :add_deps
  ]

  def run do
    if Utils.check_self_version() == :exit, do: System.halt()
    if Utils.check_mix_exs() == :exit, do: System.halt()
    if Utils.check_git_status() == :exit, do: System.halt()
    if Utils.check_mix_format() == :exit, do: System.halt()
    config = Config.new!()
    config = Enum.reduce(@checks, config, &run_check(&2, &1))

    if Config.any_changed?(config) do
      Utils.write_changes(config)
      Utils.puts("\nChanges written to disk. Cleaning up:")
      Utils.run_mix_format()
      :timer.sleep(1_000)
      Utils.run_mix_deps_get()
      Utils.run_mix_clean()
    else
      Utils.puts("\nNo changes made.")
    end
  end

  @spec run_check(Config.t(), atom()) :: Config.t()
  def run_check(%Config{} = config, :ex_doc),
    do: config |> SimpleDep.run(:ex_doc, only: :dev, runtime: false) |> unwrap(:ex_doc)

  def run_check(%Config{} = config, :earmark),
    do: config |> SimpleDep.run(:earmark, only: :dev, runtime: false) |> unwrap(:earmark)

  def run_check(%Config{} = config, :dialyxir),
    do: config |> SimpleDep.run(:dialyxir, only: :dev, runtime: false) |> unwrap(:dialyxir)

  def run_check(%Config{} = config, :mix_test_watch),
    do: config |> SimpleDep.run(:mix_test_watch, only: :dev, runtime: false) |> unwrap(:mix_test_watch)

  def run_check(%Config{} = config, :credo),
    do: config |> SimpleDep.run(:credo, only: :dev, runtime: false) |> unwrap(:credo)

  def run_check(%Config{} = config, :excoveralls),
    do: config |> SimpleDep.run(:excoveralls, only: :test) |> unwrap(:excoveralls)

  def run_check(%Config{} = config, :git_hooks),
    do: config |> SimpleDep.run(:git_hooks, only: :dev, runtime: false) |> unwrap(:git_hooks)

  def run_check(%Config{} = config, :dialyzer_config),
    do: config |> DialyzerConfig.run() |> unwrap(:dialyzer_config)

  def run_check(%Config{} = config, :git_hooks_config),
    do: config |> GitHooksConfig.run() |> unwrap(:git_hooks_config)

  def run_check(%Config{} = config, :coveralls_config),
    do: config |> CoverallsConfig.run() |> unwrap(:coveralls_config)

  def run_check(%Config{} = config, :credo_exs),
    do: config |> CredoConfig.run() |> unwrap(:credo_exs)

  def run_check(%Config{} = config, :update_all_deps),
    do: config |> UpdateAllDeps.run() |> unwrap(:update_all_deps)

  def run_check(%Config{} = config, :add_deps),
    do: config |> AddDeps.run() |> unwrap(:add_deps)

  @spec unwrap({atom(), Config.t()} | {:error, any()}, atom()) :: Config.t()
  def unwrap({:no, config}, _check), do: config
  def unwrap({:yes, config}, _check), do: config
  def unwrap({:up_to_date, config}, _check), do: config
  def unwrap({:skip, config}, _check), do: config
  def unwrap({:error, reason}, check), do: raise("Check #{check} returned #{reason}")
end
