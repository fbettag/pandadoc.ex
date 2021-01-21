defmodule PandaDoc.Model.DocumentResponse do
  @moduledoc """
  Structure with additional information about an API response holding information about a document.
  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :status,
    :uuid
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :status => String.t(),
          :uuid => String.t()
        }
end

defimpl Poison.Decoder, for: PandaDoc.Model.DocumentResponse do
  def decode(value, _options) do
    value
  end
end
