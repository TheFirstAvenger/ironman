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
    |> Regex.run(Config.get(config, :mix_exs))
    |> case do
      [_, version] -> version
      _ -> nil
    end
  end

  @spec get_configured_opts(Config.t(), dep()) :: String.t() | nil
  def get_configured_opts(%Config{} = config, dep) do
    "defp deps do.*?\\[.*?{:#{dep}, \"(.*?)\"(.*?)}"
    |> Regex.compile!("s")
    |> Regex.run(Config.get(config, :mix_exs))
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
    new_version = "~> #{available_version}"
    dep_opts_str = dep_opts_to_str(dep_opts)
    current_mix = Config.get(config, :mix_exs)

    new_mix =
      Regex.replace(
        ~r/defp deps do.*?[\n\s\S]*?\[/,
        current_mix,
        "defp deps do\n    [{:#{dep}, \"#{new_version}\"#{dep_opts_str}},"
      )

    if current_mix == new_mix do
      Utils.puts("WARNING: Installing deps didn't change mix_exs")
    end

    config =
      Config.set(
        config,
        :mix_exs,
        new_mix
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
    # TODO
    Utils.puts("Upgrading #{dep} from #{configured_version} to #{available_version}")
    new_version = "~> #{available_version}"
    regex = Regex.compile!("{:#{dep}, \"~>.*?\"")
    current_mix = Config.get(config, :mix_exs)
    new_mix = Regex.replace(regex, current_mix, "{:#{dep}, \"#{new_version}\"")

    new_mix =
      if current_mix != new_mix do
        new_mix
      else
        regex = Regex.compile!("{:#{dep}, \".*?\"")
        current_mix = Config.get(config, :mix_exs)
        new_mix = Regex.replace(regex, current_mix, "{:#{dep}, \"#{new_version}\"")

        if current_mix == new_mix do
          Utils.puts("WARNING: Upgrade of #{dep} did not change mix.exs")
        end

        new_mix
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
    mix = config |> Config.get(:mix_exs) |> remove_comments()

    "defp deps do\\s*?\\[\\s*?({.*?})\\s*?]\\s*?end"
    |> Regex.compile!("s")
    |> Regex.run(mix)
    |> case do
      nil ->
        []

      deps_ret ->
        deps_str = Enum.at(deps_ret, 1)

        "{:([a-z_]*)"
        |> Regex.compile!()
        |> Regex.scan(deps_str)
        |> Enum.map(&Enum.at(&1, 1))
    end
  end

  def remove_comments(str) do
    "^\\s*#.*$\n*"
    |> Regex.compile!("m")
    |> Regex.replace(str, "")
  end
end
