defmodule Ironman.Utils.Deps do
  @moduledoc false

  @ironman_version Mix.Project.config()[:version]

  @type dep :: atom()

  alias Ironman.{
    Config,
    Utils
  }

  @spec ironman_version() :: String.t()
  def ironman_version, do: @ironman_version

  @spec check_dep_version(Config.t(), dep()) :: {:yes | :no | :up_to_date, Config.t()} | {:error, any()}
  def check_dep_version(%Config{} = config, dep, dep_opts \\ []) when is_atom(dep) and is_list(dep_opts) do
    with(
      {:ok, available_version} <- available_version(dep),
      configured_version <- get_configured_version(config, dep)
    ) do
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
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_configured_version(Config.t(), dep()) :: String.t() | nil
  def get_configured_version(%Config{} = config, dep) do
    "defp deps do.*?\\[.*?{:#{dep}, \"(.*?)\""
    |> Regex.compile!("s")
    |> Regex.run(Config.mix_exs(config))
    |> case do
      [_, version] -> version
      _ -> nil
    end
  end

  @spec get_configured_opts(Config.t(), dep()) :: String.t() | nil
  def get_configured_opts(%Config{} = config, dep) do
    "defp deps do.*?\\[.*?{:#{dep}, \"(.*?)\"(.*?)}"
    |> Regex.compile!("s")
    |> Regex.run(Config.mix_exs(config))
    |> case do
      [_, _, ""] -> nil
      [_, _, ", " <> opts] -> "[#{opts}]" |> Code.eval_string() |> elem(0)
    end
  end

  @spec available_version(dep()) :: {:ok, String.t()} | {:error, any()}
  def available_version(dep) do
    with(
      {:ok, body} <- Ironman.Utils.get_body_as_term("https://hex.pm/api/packages/#{dep}"),
      %{"releases" => [%{"version" => version} | _]} <- body
    ) do
      {:ok, version}
    else
      {:regex, _} -> raise "Release not found on https://hex.pm/api/packages/#{dep}"
      {:error, reason} -> {:error, reason}
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
    new_version = "~> #{available_version}"
    dep_opts_str = dep_opts_to_str(dep_opts)

    config =
      Config.set_mix_exs(
        config,
        Regex.replace(
          ~r/defp deps do.*?\n.*?\[/,
          Config.mix_exs(config),
          "defp deps do\n    [{:#{dep}, \"#{new_version}\"#{dep_opts_str}},"
        )
      )

    {:yes, config}
  end

  defp dep_opts_to_str(dep_opts) do
    case dep_opts do
      [] -> ""
      [{key, value} | t] when value in [true, false, nil] -> ", #{key}: #{value}#{dep_opts_to_str(t)}"
      [{key, value} | t] when is_atom(value) -> ", #{key}: :#{value}#{dep_opts_to_str(t)}"
      [{key, value} | t] when is_binary(value) -> ", #{key}: \"#{value}\"#{dep_opts_to_str(t)}"
    end
  end

  @spec skip_install(Config.t(), dep()) :: {:no, Config.t()}
  def skip_install(%Config{} = config, dep) do
    Utils.puts("Skipping install of #{dep}")
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
    # TODO
    Utils.puts("Upgrading #{dep} from #{configured_version} to #{available_version}")
    new_version = "~> #{available_version}"
    regex = Regex.compile!("{:#{dep}, \"~>.*?\"")
    config = Config.set_mix_exs(config, Regex.replace(regex, Config.mix_exs(config), "{:#{dep}, \"#{new_version}\""))

    {:yes, config}
  end

  @spec skip_upgrade(Config.t(), any()) :: {:no, Config.t()}
  def skip_upgrade(%Config{} = config, dep) do
    Utils.puts("Skipping upgrade of #{dep}")
    {:no, config}
  end
end
