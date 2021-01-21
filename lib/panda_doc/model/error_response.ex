defmodule PandaDoc.Model.ErrorResponse do
  @moduledoc """
  Structure with additional information about an API Error response.
  """

  @derive [Poison.Encoder]
  defstruct [
    :user_msg
  ]

  @type t :: %__MODULE__{
          :user_msg => String.t()
        }
end

defimpl Poison.Decoder, for: PandaDoc.Model.ErrorResponse do
  def decode(value, _options) do
    value
  end
end
