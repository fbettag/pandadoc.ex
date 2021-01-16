defmodule PandaDoc.Client do
  @moduledoc """
  Documentation for `PandaDoc.Client` which provides low-level API functionality to the pandadoc.com API.

  """
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.pandadoc.com/public/v1")
  plug(Tesla.Middleware.KeepRequest)
  plug(Tesla.Middleware.Timeout, timeout: 30_000)
  plug(Tesla.Middleware.JSON, engine: Poison, engine_opts: [keys: :atoms])

  plug(Tesla.Middleware.Headers, [
    {"User-Agent", "Elixir"},
    {"Authorization", "API-Key #{Application.get_env(:pandadoc, :api_key)}"}
  ])

  @doc "Formats an error to a tuple of {:error, http_status, message}."
  def format_error(obj), do: format_error_(obj)

  defp format_error_({:ok, %Tesla.Env{status: status, body: %{user_msg: message}}}),
    do: {:error, status, message}

  defp format_error_({:ok, %Tesla.Env{status: status, body: body}}),
    do: {:error, status, body}

  defp format_error_({:error, _} = error), do: error
end
