defmodule Ironman.Utils.Ast do
  @moduledoc false

  alias Sourceror.Zipper

  @spec parse(String.t()) :: {:ok, Macro.t()} | {:error, any()}
  def parse(source) do
    {:ok, Sourceror.parse_string!(source)}
  rescue
    e -> {:error, e}
  end

  @spec to_string(Macro.t()) :: String.t()
  def to_string(ast) do
    Sourceror.to_string(ast)
  end

  @spec get_dep_version(String.t(), atom()) :: String.t() | nil
  def get_dep_version(source, dep_name) do
    case parse(source) do
      {:ok, ast} ->
        ast
        |> find_dep_in_ast(dep_name)
        |> case do
          {_name, version, _opts} -> version
          nil -> nil
        end

      {:error, _} ->
        nil
    end
  end

  @spec get_dep_opts(String.t(), atom()) :: keyword() | nil
  def get_dep_opts(source, dep_name) do
    case parse(source) do
      {:ok, ast} ->
        ast
        |> find_dep_in_ast(dep_name)
        |> case do
          {_name, _version, []} -> nil
          {_name, _version, opts} -> opts
          nil -> nil
        end

      {:error, _} ->
        nil
    end
  end

  @spec get_all_dep_names(String.t()) :: [atom()]
  def get_all_dep_names(source) do
    case parse(source) do
      {:ok, ast} ->
        ast
        |> find_deps_list()
        |> Enum.map(&extract_dep_name/1)
        |> Enum.reject(&is_nil/1)

      {:error, _} ->
        []
    end
  end

  @spec add_dep(String.t(), atom(), String.t(), keyword()) :: String.t()
  def add_dep(source, dep_name, version, opts \\ []) do
    case parse(source) do
      {:ok, ast} ->
        new_dep_ast = build_dep_tuple(dep_name, version, opts)

        zipper = Zipper.zip(ast)

        case find_deps_function(zipper) do
          nil ->
            source

          deps_zipper ->
            {:defp, meta, [fun_name, body]} = Zipper.node(deps_zipper)
            new_body = insert_dep_into_body(body, new_dep_ast)
            new_node = {:defp, meta, [fun_name, new_body]}

            deps_zipper
            |> Zipper.replace(new_node)
            |> Zipper.root()
            |> Sourceror.to_string()
        end

      {:error, _} ->
        source
    end
  end

  @spec update_dep_version(String.t(), atom(), String.t()) :: String.t()
  def update_dep_version(source, dep_name, new_version) do
    case parse(source) do
      {:ok, ast} ->
        zipper = Zipper.zip(ast)

        updated_zipper =
          traverse_and_update_version(zipper, dep_name, new_version)

        case updated_zipper do
          nil -> source
          z -> z |> Zipper.root() |> Sourceror.to_string()
        end

      {:error, _} ->
        source
    end
  end

  @spec add_to_project_config(String.t(), String.t()) :: String.t()
  def add_to_project_config(source, config_string) do
    case parse(source) do
      {:ok, ast} ->
        config_items = parse_config_items(config_string)

        zipper = Zipper.zip(ast)

        case find_project_function(zipper) do
          nil ->
            source

          project_zipper ->
            {:def, meta, [fun_name, body]} = Zipper.node(project_zipper)
            new_body = prepend_to_keyword_list(body, config_items)
            new_node = {:def, meta, [fun_name, new_body]}

            project_zipper
            |> Zipper.replace(new_node)
            |> Zipper.root()
            |> Sourceror.to_string()
        end

      {:error, _} ->
        source
    end
  end

  # Private helpers

  defp find_deps_function(zipper) do
    Zipper.find(zipper, fn
      {:defp, _, [{:deps, _, _}, _body]} -> true
      _ -> false
    end)
  end

  defp find_project_function(zipper) do
    Zipper.find(zipper, fn
      {:def, _, [{:project, _, _}, _body]} -> true
      _ -> false
    end)
  end

  defp traverse_and_update_version(zipper, dep_name, new_version) do
    case Zipper.next(zipper) do
      nil ->
        nil

      next_zipper ->
        node = Zipper.node(next_zipper)

        case node do
          # 3+ element tuple like {:bar, "~> 2.2", only: :test}
          {:{}, meta, [{:__block__, name_meta, [^dep_name]} | rest]} ->
            new_rest = update_version_in_rest(rest, new_version)
            new_node = {:{}, meta, [{:__block__, name_meta, [dep_name]} | new_rest]}
            Zipper.replace(next_zipper, new_node)

          # 2-element tuple like {:foo, "~> 1.1"}
          {{:__block__, name_meta, [^dep_name]}, _version_ast} ->
            new_node =
              {{:__block__, name_meta, [dep_name]}, {:__block__, [delimiter: "\""], ["~> " <> new_version]}}

            Zipper.replace(next_zipper, new_node)

          # Wrapped 2-element tuple (in __block__)
          {:__block__, block_meta, [{{:__block__, name_meta, [^dep_name]}, _version_ast}]} ->
            inner =
              {{:__block__, name_meta, [dep_name]}, {:__block__, [delimiter: "\""], ["~> " <> new_version]}}

            new_node = {:__block__, block_meta, [inner]}
            Zipper.replace(next_zipper, new_node)

          _ ->
            traverse_and_update_version(next_zipper, dep_name, new_version)
        end
    end
  end

  defp parse_config_items(config_string) do
    case parse("[" <> config_string <> "]") do
      {:ok, ast} -> extract_keyword_items(ast)
      {:error, _} -> []
    end
  end

  defp extract_keyword_items({:__block__, _, [items]}) when is_list(items), do: items
  defp extract_keyword_items(items) when is_list(items), do: items
  defp extract_keyword_items(_), do: []

  defp find_dep_in_ast(ast, dep_name) do
    deps_list = find_deps_list(ast)

    Enum.find_value(deps_list, fn dep_tuple ->
      case extract_dep_info(dep_tuple) do
        {^dep_name, version, opts} -> {dep_name, version, opts}
        _ -> nil
      end
    end)
  end

  defp find_deps_list(ast) do
    zipper = Zipper.zip(ast)

    case find_deps_function(zipper) do
      nil ->
        []

      deps_zipper ->
        {:defp, _, [_, body]} = Zipper.node(deps_zipper)
        extract_list_from_body(body)
    end
  end

  defp extract_list_from_body(body) do
    case body do
      [{{:__block__, _, [:do]}, {:__block__, _, [list]}}] when is_list(list) -> list
      [{{:__block__, _, [:do]}, list}] when is_list(list) -> list
      [do: {:__block__, _, [list]}] when is_list(list) -> list
      [do: list] when is_list(list) -> list
      _ -> []
    end
  end

  defp extract_dep_name(dep_tuple) do
    case extract_dep_info(dep_tuple) do
      {name, _version, _opts} -> name
      nil -> nil
    end
  end

  # 3+ element tuple with options: {:{}, meta, [{:__block__, _, [:name]}, version_block, opts...]}
  defp extract_dep_info({:{}, _, [{:__block__, _, [name]} | rest]}) when is_atom(name) do
    version = extract_version_from_rest(rest)
    opts = extract_opts_from_rest(rest)
    {name, version, opts}
  end

  # Wrapped 2-element tuple: {:__block__, _, [{{:__block__, _, [:name]}, version}]}
  defp extract_dep_info({:__block__, _, [{{:__block__, _, [name]}, version_ast}]}) when is_atom(name) do
    version = extract_version_string(version_ast)
    {name, version, []}
  end

  # 2-element tuple: {{:__block__, _, [:name]}, version}
  defp extract_dep_info({{:__block__, _, [name]}, version_ast}) when is_atom(name) do
    version = extract_version_string(version_ast)
    {name, version, []}
  end

  defp extract_dep_info(_), do: nil

  defp extract_version_from_rest([{:__block__, _, [version]} | _]) when is_binary(version), do: version

  defp extract_version_from_rest(_), do: nil

  defp extract_opts_from_rest([_version, opts]) when is_list(opts), do: ast_to_keyword_list(opts)
  defp extract_opts_from_rest(_), do: []

  defp ast_to_keyword_list(ast_list) do
    Enum.flat_map(ast_list, fn
      {{:__block__, _, [key]}, {:__block__, _, [value]}} -> [{key, value}]
      _ -> []
    end)
  end

  defp extract_version_string({:__block__, _, [version]}) when is_binary(version), do: version
  defp extract_version_string(_), do: nil

  defp build_dep_tuple(name, version, []) do
    # Wrap in __block__ so it renders as a tuple literal, not a keyword pair
    inner =
      {{:__block__, [], [name]}, {:__block__, [delimiter: "\""], ["~> " <> version]}}

    {:__block__, [], [inner]}
  end

  defp build_dep_tuple(name, version, opts) do
    opts_ast =
      Enum.map(opts, fn {key, value} ->
        {{:__block__, [format: :keyword], [key]}, {:__block__, build_value_meta(value), [value]}}
      end)

    {:{}, [],
     [
       {:__block__, [], [name]},
       {:__block__, [delimiter: "\""], ["~> " <> version]}
       | [opts_ast]
     ]}
  end

  defp build_value_meta(value) when is_binary(value), do: [delimiter: "\""]
  defp build_value_meta(_value), do: []

  defp insert_dep_into_body(body, new_dep) do
    case body do
      # Empty list wrapped in block: {:__block__, meta, [[]]}
      [{{:__block__, do_meta, [:do]}, {:__block__, block_meta, [[]]}}] ->
        [{{:__block__, do_meta, [:do]}, {:__block__, block_meta, [[new_dep]]}}]

      [{{:__block__, do_meta, [:do]}, {:__block__, block_meta, [list]}}] when is_list(list) ->
        [{{:__block__, do_meta, [:do]}, {:__block__, block_meta, [[new_dep | list]]}}]

      [{{:__block__, do_meta, [:do]}, list}] when is_list(list) ->
        [{{:__block__, do_meta, [:do]}, [new_dep | list]}]

      [do: {:__block__, meta, [[]]}] ->
        [do: {:__block__, meta, [[new_dep]]}]

      [do: {:__block__, meta, [list]}] when is_list(list) ->
        [do: {:__block__, meta, [[new_dep | list]]}]

      [do: list] when is_list(list) ->
        [do: [new_dep | list]]

      other ->
        other
    end
  end

  defp update_version_in_rest([_old_version | rest], new_version) do
    [{:__block__, [delimiter: "\""], ["~> " <> new_version]} | rest]
  end

  defp prepend_to_keyword_list(body, items) do
    case body do
      [{{:__block__, do_meta, [:do]}, {:__block__, block_meta, [list]}}] when is_list(list) ->
        [{{:__block__, do_meta, [:do]}, {:__block__, block_meta, [items ++ list]}}]

      [{{:__block__, do_meta, [:do]}, list}] when is_list(list) ->
        [{{:__block__, do_meta, [:do]}, items ++ list}]

      [do: {:__block__, meta, [list]}] when is_list(list) ->
        [do: {:__block__, meta, [items ++ list]}]

      [do: list] when is_list(list) ->
        [do: items ++ list]

      other ->
        other
    end
  end
end
