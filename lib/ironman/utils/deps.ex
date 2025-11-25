defmodule Ironman.Utils.Deps do
  @moduledoc false

  alias Ironman.Config
  alias Ironman.Utils
  alias Ironman.Utils.Ast

  @ironman_version Mix.Project.config()[:version]

  @type dep :: atom()

  @spec ironman_version() :: String.t()
  def ironman_version, do: @ironman_version

  @spec check_dep_version(Config.t(), dep()) :: {:yes | :no | :up_to_date, Config.t()} | {:error, any()}
  def check_dep_version(%Config{} = config, dep, dep_opts \\ []) when is_atom(dep) and is_list(dep_opts) do
    with({:ok, available_version} <- available_version(dep)) do
      configured_version = get_configured_version(config, dep)

      case configured_version do
        nil ->
          offer_dep_install(config, dep, dep_opts, available_version)

        configured_version ->
          if String.contains?(configured_version, available_version) do
            Utils.puts("#{dep} is up to date (#{available_version})")
            {:up_to_date, config}
          else
            offer_dep_upgrade(config, dep, configured_version, available_version)
          end
      end
    end
  end

  @spec get_configured_version(Config.t(), dep()) :: String.t() | nil
  def get_configured_version(%Config{} = config, dep) do
    config
    |> Config.get(:mix_exs)
    |> Ast.get_dep_version(dep)
  end

  @spec get_configured_opts(Config.t(), dep()) :: keyword() | nil
  def get_configured_opts(%Config{} = config, dep) do
    config
    |> Config.get(:mix_exs)
    |> Ast.get_dep_opts(dep)
  end

  @spec available_version(dep()) :: {:ok, String.t()} | {:error, any()}
  def available_version(dep) do
    with(
      {:ok, body} <- Utils.get_body_as_term("https://hex.pm/api/packages/#{dep}"),
      %{"releases" => [%{"version" => version} | _]} <- body
    ) do
      {:ok, version}
    else
      {:error, reason} -> {:error, reason}
      _ -> raise "Could not parse release in body of https://hex.pm/api/packages/#{dep}"
    end
  end

  @spec offer_dep_install(Config.t(), dep(), keyword(), String.t()) :: {:no | :yes, Config.t()}
  def offer_dep_install(config, dep, dep_opts, available_version) do
    Utils.ask(
      "Install #{dep} #{available_version}?",
      fn -> do_install(config, dep, dep_opts, available_version) end,
      fn -> skip_install(config, dep) end
    )
  end

  @spec do_install(Config.t(), dep(), keyword(), String.t()) :: {:yes, Config.t()}
  def do_install(%Config{} = config, dep, dep_opts, available_version) do
    Utils.puts("Installing #{dep} #{available_version}")
    current_mix = Config.get(config, :mix_exs)

    new_mix = Ast.add_dep(current_mix, dep, available_version, dep_opts)

    if current_mix == new_mix do
      Utils.puts("WARNING: Installing deps didn't change mix_exs")
    end

    config = Config.set(config, :mix_exs, new_mix)

    {:yes, config}
  end

  @spec skip_install(Config.t(), dep()) :: {:no, Config.t()}
  def skip_install(%Config{} = config, dep) do
    Utils.puts("\nDeclined install of #{dep}")
    {:no, config}
  end

  @spec offer_dep_upgrade(Config.t(), dep(), String.t(), String.t()) :: {:yes | :no, Config.t()}
  def offer_dep_upgrade(%Config{} = config, dep, configured_version, available_version) do
    Utils.ask(
      "Upgrade #{dep} from #{configured_version} to #{available_version}?",
      fn -> do_upgrade(config, dep, configured_version, available_version) end,
      fn -> skip_upgrade(config, dep) end
    )
  end

  @spec do_upgrade(Config.t(), dep(), String.t(), String.t()) :: {:yes, Config.t()}
  def do_upgrade(%Config{} = config, dep, configured_version, available_version) do
    Utils.puts("Upgrading #{dep} from #{configured_version} to #{available_version}")
    current_mix = Config.get(config, :mix_exs)

    new_mix = Ast.update_dep_version(current_mix, dep, available_version)

    if current_mix == new_mix do
      Utils.puts("WARNING: Upgrade of #{dep} did not change mix.exs")
    end

    config = Config.set(config, :mix_exs, new_mix)

    {:yes, config}
  end

  @spec skip_upgrade(Config.t(), any()) :: {:no, Config.t()}
  def skip_upgrade(%Config{skipped_upgrades: skipped_upgrades} = config, dep) do
    Utils.puts("\nDeclined upgrade of #{dep}")
    {:no, %{config | skipped_upgrades: MapSet.put(skipped_upgrades, dep)}}
  end

  def get_installed_deps(%Config{} = config) do
    config
    |> Config.get(:mix_exs)
    |> Ast.get_all_dep_names()
    |> Enum.map(&Atom.to_string/1)
  end
end
