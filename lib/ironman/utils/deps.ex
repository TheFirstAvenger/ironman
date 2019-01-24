defmodule Ironman.Utils.Deps do
  @moduledoc false

  @type dep :: atom()

  alias Ironman.{
    Config,
    Utils
  }

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
  def get_configured_version(%Config{deps: deps}, dep) do
    deps
    |> Enum.find(fn d -> elem(d, 0) == dep end)
    |> case do
      nil -> nil
      d -> elem(d, 1)
    end
  end

  @spec available_version(dep()) :: {:ok, String.t()} | {:error, any()}
  def available_version(dep) do
    with(
      {:ok, body} <- Ironman.Utils.get_body("https://hex.pm/api/packages/#{dep}"),
      {:regex, [_ | [version | _]]} <- {:regex, Regex.run(~r/"releases":\[{.*?"version":"(.*?)"/, body)}
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
      fn -> skip_install(config, dep) end,
      fn -> offer_dep_install(config, dep, dep_opts, available_version) end
    )
  end

  @spec do_install(Config.t(), dep(), keyword(), String.t()) :: {:yes, Config.t()}
  def do_install(%Config{mix_exs: mix_exs} = config, dep, dep_opts, available_version) do
    Utils.puts("Installing #{dep} #{available_version}")
    new_version = "~> #{available_version}"
    dep_opts_str = dep_opts_to_str(dep_opts)

    mix_exs =
      Regex.replace(
        ~r/defp deps do.*?\n.*?\[/,
        mix_exs,
        "defp deps do\n    [{:#{dep}, \"#{new_version}\"#{dep_opts_str}},"
      )

    {:yes, %Config{config | mix_exs: mix_exs, changed: true} |> add_dep_to_state(dep, dep_opts, new_version)}
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
      fn -> skip_upgrade(config, dep) end,
      fn -> offer_dep_upgrade(config, dep, configured_version, available_version) end
    )
  end

  @spec do_upgrade(Config.t(), dep(), String.t(), String.t()) :: {:yes, Config.t()}
  def do_upgrade(%Config{mix_exs: mix_exs} = config, dep, configured_version, available_version) do
    # TODO
    Utils.puts("Upgrading #{dep} from #{configured_version} to #{available_version}")
    new_version = "~> #{available_version}"
    regex = Regex.compile!("{:#{dep}, \"~>.*?\"")
    mix_exs = Regex.replace(regex, mix_exs, "{:#{dep}, \"#{new_version}\"")

    {:yes, %Config{config | mix_exs: mix_exs, changed: true} |> update_deps_state(dep, new_version)}
  end

  @spec update_deps_state(Ironman.Config.t(), dep(), String.t()) :: Ironman.Config.t()
  def update_deps_state(%Config{deps: deps} = config, dep, new_version) do
    deps =
      Enum.map(deps, fn d ->
        case elem(d, 0) do
          ^dep -> d |> Tuple.delete_at(1) |> Tuple.insert_at(1, new_version)
          _ -> d
        end
      end)

    %Config{config | deps: deps}
  end

  @spec add_dep_to_state(Ironman.Config.t(), dep(), keyword(), String.t()) :: Ironman.Config.t()
  def add_dep_to_state(%Config{deps: deps} = config, dep, dep_opts, new_version) do
    new_dep =
      case dep_opts do
        [] -> {dep, new_version}
        _ -> {dep, new_version, dep_opts}
      end

    %Config{config | deps: [new_dep | deps]}
  end

  @spec skip_upgrade(Config.t(), any()) :: {:no, Config.t()}
  def skip_upgrade(%Config{} = config, dep) do
    Utils.puts("Skipping upgrade of #{dep}")
    {:no, config}
  end
end
