defmodule PandaDoc.Model.Recipient do
  @moduledoc """
  Structure holding information about a Document signer/recipient.
  """

  @derive [Poison.Encoder]
  defstruct [
    :email,
    :first_name,
    :last_name,
    :role
  ]

  @type t :: %__MODULE__{
          :email => String.t(),
          :first_name => String.t(),
          :last_name => String.t(),
          :role => String.t()
        }
end

defimpl Poison.Decoder, for: PandaDoc.Model.Recipient do
  @moduledoc "Deserialization Helper for Poison."
  def decode(value, _options) do
    value
  end
end
