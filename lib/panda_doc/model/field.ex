defmodule PandaDoc.Model.Field do
  @moduledoc """
  Structure holding information about a Document field.
  """

  @derive [Poison.Encoder]
  defstruct [
    :value,
    :role
  ]

  @type t :: %__MODULE__{
          :value => String.t(),
          :role => String.t()
        }
end

defimpl Poison.Decoder, for: PandaDoc.Model.Field do
  def decode(value, _options) do
    value
  end
end
