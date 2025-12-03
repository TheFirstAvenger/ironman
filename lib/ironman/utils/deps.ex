defmodule Ironman.Utils.Deps do
  @moduledoc false

  alias Ironman.Config
  alias Ironman.Utils

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
    |> find_dep_in_deps_function(dep)
    |> case do
      {:ok, {_dep_atom, version, _opts}} -> version
      :not_found -> nil
    end
  end

  @spec get_configured_opts(Config.t(), dep()) :: keyword() | nil
  def get_configured_opts(%Config{} = config, dep) do
    config
    |> Config.get(:mix_exs)
    |> find_dep_in_deps_function(dep)
    |> case do
      {:ok, {_dep_atom, _version, []}} -> nil
      {:ok, {_dep_atom, _version, opts}} -> opts
      :not_found -> nil
    end
  end

  defp find_dep_in_deps_function(mix_exs, dep) do
    case Code.string_to_quoted(mix_exs) do
      {:ok, ast} ->
        deps_list = extract_deps_list(ast)
        find_dep_in_list(deps_list, dep)

      {:error, _} ->
        :not_found
    end
  end

  defp extract_deps_list(ast) do
    {_ast, deps} =
      Macro.prewalk(ast, nil, fn
        {:defp, _, [{:deps, _, _}, [do: deps_list]]} = node, _acc ->
          {node, deps_list}

        node, acc ->
          {node, acc}
      end)

    deps
  end

  defp find_dep_in_list(nil, _dep), do: :not_found
  defp find_dep_in_list([], _dep), do: :not_found

  defp find_dep_in_list(deps_list, dep) when is_list(deps_list) do
    Enum.find_value(deps_list, :not_found, fn
      # 3-element tuple AST: {:dep, version, opts}
      {:{}, _, [^dep, version | opts_list]} ->
        opts = List.flatten(opts_list)
        {:ok, {dep, version, opts}}

      # 2-element tuple that looks like keyword: [dep: version]
      {^dep, version} when is_binary(version) ->
        {:ok, {dep, version, []}}

      _ ->
        nil
    end)
  end

  defp find_dep_in_list(_other, _dep), do: :not_found

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

    new_mix = insert_dep_into_mix(current_mix, dep, "~> #{available_version}", dep_opts)

    if current_mix == new_mix do
      Utils.puts("WARNING: Installing deps didn't change mix_exs")
    end

    config = Config.set(config, :mix_exs, new_mix)

    {:yes, config}
  end

  defp insert_dep_into_mix(mix_exs, dep, version, opts) do
    case Code.string_to_quoted(mix_exs, columns: true, token_metadata: true) do
      {:ok, ast} ->
        case find_deps_list_location(ast) do
          {:ok, line, _col} ->
            insert_dep_at_line(mix_exs, line, dep, version, opts)

          {:keyword_list, start_line, first_dep} ->
            insert_dep_before_first(mix_exs, start_line, first_dep, dep, version, opts)

          :empty_list ->
            replace_empty_deps_list(mix_exs, dep, version, opts)

          :not_found ->
            mix_exs
        end

      {:error, _} ->
        mix_exs
    end
  end

  defp insert_dep_before_first(mix_exs, start_line, first_dep, dep, version, opts) do
    dep_str = format_dep_tuple(dep, version, opts)
    pattern = ~r/(\{:#{first_dep},)/

    mix_exs
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {line, idx} ->
      if idx > start_line and Regex.match?(pattern, line), do: dep_str <> ",\n" <> line, else: line
    end)
  end

  defp replace_empty_deps_list(mix_exs, dep, version, opts) do
    dep_str = format_dep_tuple(dep, version, opts)
    new_list = "[\n#{dep_str}\n    ]"

    # Match the deps list from [ to ] (including comments), replace with fresh list
    pattern = ~r/(defp deps do\s*)\[.*?\]/s

    Regex.replace(pattern, mix_exs, "\\1#{new_list}", global: false)
  end

  defp find_deps_list_location(ast) do
    {_ast, result} =
      Macro.prewalk(ast, :not_found, fn
        {:defp, meta, [{:deps, _, _}, [do: deps_list]]} = node, _acc ->
          location = get_list_opening_location(deps_list, meta)
          {node, location}

        node, acc ->
          {node, acc}
      end)

    result
  end

  defp get_list_opening_location(list, defp_meta) when is_list(list) do
    case list do
      # 3-element tuple has metadata
      [{:{}, meta, _} | _] ->
        {:ok, meta[:line], meta[:column] || 1}

      # Keyword list (2-element tuples) - no per-element metadata available
      # We'll use a marker to indicate we need to search in the source text
      [{atom, _value} | _] when is_atom(atom) ->
        do_meta = Keyword.get(defp_meta, :do, [])
        line = Keyword.get(do_meta, :line, 1)
        {:keyword_list, line, atom}

      [] ->
        :empty_list
    end
  end

  defp get_list_opening_location(_other, _meta), do: :not_found

  defp insert_dep_at_line(mix_exs, target_line, dep, version, opts) do
    dep_str = format_dep_tuple(dep, version, opts)

    mix_exs
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {line, idx} ->
      if idx == target_line, do: dep_str <> ",\n" <> line, else: line
    end)
  end

  defp format_dep_tuple(dep, version, []) do
    "      {:#{dep}, \"#{version}\"}"
  end

  defp format_dep_tuple(dep, version, opts) do
    opts_str = Enum.map_join(opts, ", ", &format_opt/1)
    "      {:#{dep}, \"#{version}\", #{opts_str}}"
  end

  defp format_opt({key, value}) when value in [true, false, nil], do: "#{key}: #{value}"
  defp format_opt({key, value}) when is_atom(value), do: "#{key}: :#{value}"
  defp format_opt({key, value}) when is_binary(value), do: "#{key}: \"#{value}\""

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
    new_version = "~> #{available_version}"

    new_mix = update_dep_version_in_mix(current_mix, dep, new_version)

    if current_mix == new_mix do
      Utils.puts("WARNING: Upgrade of #{dep} did not change mix.exs")
    end

    config = Config.set(config, :mix_exs, new_mix)

    {:yes, config}
  end

  defp update_dep_version_in_mix(mix_exs, dep, new_version) do
    pattern = ~r/(\{:#{dep},\s*")[^"]*(")/
    Regex.replace(pattern, mix_exs, "\\1#{new_version}\\2", global: false)
  end

  @spec skip_upgrade(Config.t(), any()) :: {:no, Config.t()}
  def skip_upgrade(%Config{skipped_upgrades: skipped_upgrades} = config, dep) do
    Utils.puts("\nDeclined upgrade of #{dep}")
    {:no, %{config | skipped_upgrades: MapSet.put(skipped_upgrades, dep)}}
  end

  def get_installed_deps(%Config{} = config) do
    mix_exs = Config.get(config, :mix_exs)

    case Code.string_to_quoted(mix_exs) do
      {:ok, ast} ->
        deps_list = extract_deps_list(ast)
        extract_dep_names(deps_list)

      {:error, _} ->
        []
    end
  end

  defp extract_dep_names(deps_list) when is_list(deps_list) do
    Enum.flat_map(deps_list, fn
      {:{}, _, [dep | _]} when is_atom(dep) -> [Atom.to_string(dep)]
      {dep, version} when is_atom(dep) and is_binary(version) -> [Atom.to_string(dep)]
      _ -> []
    end)
  end

  defp extract_dep_names(_), do: []
end
