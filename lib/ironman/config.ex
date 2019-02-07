defmodule Ironman.Config do
  @moduledoc """
  This struct represents the state of the project. It is created at the beginning of a run, passed through
  all the checks, where it is updated, and then mix.exs is written out at the end based on its contents.
  """
  @type t :: %__MODULE__{
          mix_exs: String.t(),
          changed: boolean()
        }
  defstruct mix_exs: nil,
            changed: false

  def new!() do
    %__MODULE__{
      mix_exs: File.read!("mix.exs")
    }
  end
end
