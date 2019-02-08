defmodule Ironman.Runner do
  @moduledoc false
  alias Ironman.Checks.SimpleDep
  alias Ironman.{Config, Utils}

  @checks [:ex_doc, :earmark, :dialyxir, :mix_test_watch, :credo, :excoveralls, :git_hooks]

  def run do
    if Utils.check_self_version() == :exit, do: System.halt()
    if Utils.check_mix_format() == :exit, do: System.halt()
    config = Config.new!()
    %Config{changed: changed} = config = Enum.reduce(@checks, config, &run_check(&2, &1))

    if changed do
      Utils.write_mix_exs(config)
      Utils.run_mix_format()
      Utils.run_mix_deps_get()
      Utils.run_mix_clean()
    else
      Utils.puts("No changes required.")
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
    do: config |> SimpleDep.run(:git_hooks, only: :test) |> unwrap(:git_hooks)

  @spec unwrap({atom(), Config.t()} | {:error, any()}, atom()) :: Config.t()
  def unwrap({:no, config}, _check), do: config
  def unwrap({:yes, config}, _check), do: config
  def unwrap({:up_to_date, config}, _check), do: config
  def unwrap({:error, reason}, check), do: raise("Check #{check} returned #{reason}")

  # @spec run_check!(Config.t(), atom()) :: Ironman.Config.t()
  # def run_check!(%Config{} = config, check) when is_atom(check) do
  #   case run_check(config, check) do
  #     {:ok, config} -> config
  #     {:error, reason} -> raise "Error running check #{check}: #{inspect(reason)}"
  #   end
  # end
end
