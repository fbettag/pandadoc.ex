defmodule PandaDoc.Model.DocumentListResponse do
  @moduledoc """
  Structure containing a list of document responses.
  """

  @derive [Poison.Encoder]
  defstruct [
    :results
  ]

  @type t :: %__MODULE__{
          :results => list(PandaDoc.Model.DocumentResponse.t())
        }
end

defimpl Poison.Decoder, for: PandaDoc.Model.DocumentListResponse do
  import PandaDoc.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:results, :list, PandaDoc.Model.DocumentResponse, options)
  end
end
