defmodule PandaDoc.Connection do
  @moduledoc """
  Documentation for `PandaDoc.Connection` which provides low-level API functionality to the pandadoc.com API.

  **It is used for low-level communication and should not be used directly by users of this library.**
  """

  @doc "Creates a new API Connection for the given API Key by returning a pre-configured `Tesla` HTTP Client."
  @spec new(String.t() | nil) :: Tesla.Env.client()
  def new(api_key \\ Application.get_env(:pandadoc, :api_key)) do
    [
      {Tesla.Middleware.BaseUrl, "https://api.pandadoc.com/public/v1"},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      {Tesla.Middleware.JSON, engine: Poison, engine_opts: [keys: :atoms]},
      {Tesla.Middleware.Headers,
       [
         {"User-Agent", "Elixir"},
         {"Authorization", "API-Key #{api_key}"}
       ]}
    ]
    |> Tesla.client()
  end
end
