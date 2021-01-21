defmodule PandaDoc.Model.BasicDocumentResponse do
  @moduledoc """
  Structure with additional information about an API response with basic informations about documents.
  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :status,
    :uuid,
    :expires_at
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :status => String.t(),
          :uuid => String.t(),
          :expires_at => DateTime.t() | nil
        }
end

defimpl Poison.Decoder, for: PandaDoc.Model.BasicDocumentResponse do
  def decode(value, _options) do
    value
  end
end
