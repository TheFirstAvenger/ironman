defmodule Ironman.Config do
  @moduledoc """
  This struct represents the state of the project. It is created at the beginning of a run, passed through
  all the checks, where it is updated, and then files are written out at the end based on its contents.
  """

  alias Ironman.{Config, Utils}
  alias Ironman.Utils.File, as: IFile

  @settable_keys [
    :mix_exs,
    :gitignore,
    :dialyzer_ignore,
    :config_exs,
    :config_test_exs,
    :config_dev_exs,
    :config_prod_exs,
    :credo_exs,
    :coveralls_json
  ]

  @type t :: %__MODULE__{
          mix_exs: String.t(),
          gitignore: String.t() | nil,
          dialyzer_ignore: String.t() | nil,
          config_exs: String.t(),
          config_test_exs: String.t() | nil,
          config_dev_exs: String.t() | nil,
          config_prod_exs: String.t() | nil,
          starting_project_config: keyword(),
          credo_exs: String.t() | nil,
          coveralls_json: String.t() | nil,
          changed: MapSet.t(atom())
        }
  defstruct mix_exs: nil,
            gitignore: nil,
            dialyzer_ignore: nil,
            config_exs: nil,
            config_test_exs: nil,
            config_dev_exs: nil,
            config_prod_exs: nil,
            starting_project_config: nil,
            credo_exs: nil,
            coveralls_json: nil,
            changed: MapSet.new()

  def new!() do
    %__MODULE__{
      mix_exs: file_or_nil(Utils.path_of(:mix_exs)),
      config_exs: file_or_nil(Utils.path_of(:config_exs)),
      config_dev_exs: file_or_nil(Utils.path_of(:config_dev_exs)),
      config_test_exs: file_or_nil(Utils.path_of(:config_test_exs)),
      config_prod_exs: file_or_nil(Utils.path_of(:config_prod_exs)),
      gitignore: file_or_nil(Utils.path_of(:gitignore)),
      dialyzer_ignore: file_or_nil(Utils.path_of(:dialyzer_ignore)),
      credo_exs: file_or_nil(Utils.path_of(:credo_exs)),
      coveralls_json: file_or_nil(Utils.path_of(:coveralls_json)),
      starting_project_config: Mix.Project.config()
    }
  end

  def get(%Config{} = config, key), do: Map.get(config, key)

  @spec set(Config.t(), atom(), String.t(), boolean()) :: Config.t()
  def set(%Config{changed: changed} = config, key, value, changed_flag \\ true) when key in @settable_keys do
    config =
      if changed_flag and get(config, key) != value do
        %Config{config | changed: MapSet.put(changed, key)}
      else
        config
      end

    Map.put(config, key, value)
  end

  def changed?(%Config{changed: changed}, key), do: MapSet.member?(changed, key)

  def any_changed?(%Config{changed: changed}), do: MapSet.size(changed) > 0

  def app_name(%Config{starting_project_config: starting_project_config}) do
    starting_project_config
    |> Keyword.fetch!(:app)
    |> parent_folder_if_nil()
  end

  defp parent_folder_if_nil(nil), do: File.cwd!() |> String.split("/") |> List.last()
  defp parent_folder_if_nil(x), do: x

  defp file_or_nil(path) do
    if IFile.exists?(path) do
      IFile.read!(path)
    else
      nil
    end
  end
end
