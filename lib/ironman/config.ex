defmodule Ironman.Config do
  @moduledoc """
  This struct represents the state of the project. It is created at the beginning of a run, passed through
  all the checks, where it is updated, and then files are written out at the end based on its contents.
  """

  alias Ironman.Config
  alias Ironman.Utils.File, as: IFile

  @type t :: %__MODULE__{
          mix_exs: String.t(),
          mix_exs_changed: boolean(),
          gitignore: String.t() | nil,
          gitignore_changed: boolean(),
          dialyzer_ignore: String.t() | nil,
          dialyzer_ignore_changed: boolean(),
          starting_project_config: keyword()
        }
  defstruct mix_exs: nil,
            mix_exs_changed: false,
            gitignore: nil,
            gitignore_changed: false,
            dialyzer_ignore: nil,
            dialyzer_ignore_changed: false,
            starting_project_config: nil

  def new!() do
    %__MODULE__{
      mix_exs: file_or_nil("mix.exs"),
      gitignore: file_or_nil(".gitignore"),
      dialyzer_ignore: file_or_nil(".dialyzer_ignore.exs"),
      starting_project_config: Mix.Project.config()
    }
  end

  ## Getters
  def starting_project_config(%Config{starting_project_config: starting_project_config}), do: starting_project_config
  def mix_exs(%Config{mix_exs: mix_exs}), do: mix_exs
  def gitignore(%Config{gitignore: gitignore}), do: gitignore
  def dialyzer_ignore(%Config{dialyzer_ignore: dialyzer_ignore}), do: dialyzer_ignore

  ## Setters when not actually changed

  def set_mix_exs(%Config{mix_exs: mix_exs} = config, new_content)
      when new_content == mix_exs,
      do: config

  def set_mix_exs(%Config{} = config, new_content),
    do: %Config{config | mix_exs: new_content, mix_exs_changed: true}

  def set_gitignore(%Config{gitignore: gitignore} = config, new_content)
      when new_content == gitignore,
      do: config

  def set_gitignore(%Config{} = config, new_content),
    do: %Config{config | gitignore: new_content, gitignore_changed: true}

  def set_dialyzer_ignore(%Config{dialyzer_ignore: dialyzer_ignore} = config, new_content)
      when new_content == dialyzer_ignore,
      do: config

  def set_dialyzer_ignore(%Config{} = config, new_content),
    do: %Config{config | dialyzer_ignore: new_content, dialyzer_ignore_changed: true}

  def mix_exs_changed(%Config{mix_exs_changed: mix_exs_changed}), do: mix_exs_changed
  def gitignore_changed(%Config{gitignore_changed: gitignore_changed}), do: gitignore_changed
  def dialyzer_ignore_changed(%Config{dialyzer_ignore_changed: dialyzer_ignore_changed}), do: dialyzer_ignore_changed

  def app_name(%Config{starting_project_config: starting_project_config}),
    do: Keyword.fetch!(starting_project_config, :app)

  defp file_or_nil(path) do
    if IFile.exists?(path) do
      IFile.read!(path)
    else
      nil
    end
  end
end
