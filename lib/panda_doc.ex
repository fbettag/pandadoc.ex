defmodule PandaDoc do
  @moduledoc """
  Documentation for `PandaDoc` which provides low-level API functionality to the pandadoc.com API.

  """
  use Tesla
  alias Tesla.Multipart

  plug(Tesla.Middleware.BaseUrl, "https://api.pandadoc.com/public/v1")
  plug(Tesla.Middleware.KeepRequest)

  plug(Tesla.Middleware.Headers, [
    {"User-Agent", "Elixir"},
    {"Authorization", "API-Key #{Application.get_env(:pandadoc, :api_key)}"}
  ])

  plug(Tesla.Middleware.Timeout, timeout: 30_000)
  plug(Tesla.Middleware.JSON, engine: Poison, engine_opts: [keys: :atoms])

  defp format_error({:ok, %Tesla.Env{status: status, body: %{user_msg: message}}}),
    do: {:error, status, message}

  defp format_error({:ok, %Tesla.Env{status: status, body: body}}),
    do: {:error, status, body}

  defp format_error({:error, _} = error), do: error

  @doc """
  Creates a new Document from the given PDF file.

  ## Examples

  iex> pdf_bytes = []
  iex> recipients = [%{email: "jane@example.com", first_name: "Jane", last_name: "Example", role: "user"}]
  iex> PandaDoc.create_document("Sample PandaDoc PDF.pdf", <<pdf_bytes>>, recipients)
  {:ok, "msFYActMfJHqNTKH8YSvF1"}

  """
  def create_document(
        name,
        pdf_bytes,
        recipients,
        fields \\ %{},
        tags \\ [],
        parse_form_fields \\ false
      ) do
    json =
      %{
        name: name,
        tags: tags,
        fields: fields,
        recipients: recipients,
        parse_form_fields: parse_form_fields
      }
      |> Poison.encode!()

    mp =
      Multipart.new()
      |> Multipart.add_content_type_param("charset=utf-8")
      |> Multipart.add_field("data", json)
      |> Multipart.add_file_content(pdf_bytes, name,
        headers: [{"content-type", "application/pdf"}]
      )

    case post("/documents", mp) do
      {:ok, %Tesla.Env{body: %{id: id, status: "document.uploaded", uuid: _uuid}}} ->
        {:ok, id}

      error ->
        format_error(error)
    end
  end

  @doc """
  Move a document to sent status and send an optional email.

  ## Examples

  iex> PandaDoc.send_document("msFYActMfJHqNTKH8YSvF1", "Document ready", "Hi there, please sign this document")
  :ok

  """
  def send_document(id, subject \\ nil, message \\ nil, silent \\ false) do
    json = %{
      subject: subject,
      message: message,
      silent: silent
    }

    case post("/documents/#{id}/send", json) do
      {:ok, %Tesla.Env{body: %{id: _id, status: "document.sent", uuid: _uuid}}} ->
        :ok

      error ->
        format_error(error)
    end
  end

  @doc """
  Get basic data about a document such as name, status, and dates.

  ## Examples

  iex> PandaDoc.document_status("msFYActMfJHqNTKH8YSvF1")
  {:ok, %{}}

  """
  def document_status(id) do
    case get("/documents/#{id}") do
      {:ok, %Tesla.Env{body: %{id: _id, status: _status, uuid: _uuid} = info}} ->
        {:ok, info}

      error ->
        format_error(error)
    end
  end

  @doc """
  Generate a link to share this document.

  ## Examples

  iex> PandaDoc.share_document("msFYActMfJHqNTKH8YSvF1", "jane@example.com", 900)
  {:ok, "https://app.pandadoc.com/s/QYCPtavst3DqqBK72ZRtbF", ~U[2017-08-29T22:18:44.315Z]}

  """
  def share_document(id, recipient_email, lifetime \\ 86_400) do
    json = %{
      recipient: recipient_email,
      lifetime: lifetime
    }

    case post("/documents/#{id}/session", json) do
      {:ok, %Tesla.Env{body: %{id: id, expires_at: expires_at}}} ->
        {:ok, expires_at, _} = DateTime.from_iso8601(expires_at)
        {:ok, "https://app.pandadoc.com/s/#{id}", expires_at}

      error ->
        format_error(error)
    end
  end

  @doc """
  Download a PDF of any document.

  ## Examples

  iex> PandaDoc.download_document("msFYActMfJHqNTKH8YSvF1", watermark_text: "WATERMARKED")
  {:ok, []}

  """
  def download_document(id, query \\ []) do
    case get("/documents/#{id}/download", query: query) do
      {:ok, %Tesla.Env{body: pdf_bytes}} ->
        {:ok, pdf_bytes}

      error ->
        format_error(error)
    end
  end

  @doc """
  Download a signed PDF of a completed document.

  ## Examples

  iex> PandaDoc.download_protected_document("msFYActMfJHqNTKH8YSvF1")
  {:ok, []}

  """
  def download_protected_document(id, hard_copy_type \\ nil) do
    query =
      if hard_copy_type == nil,
        do: [],
        else: [hard_copy_type: hard_copy_type]

    case get("/documents/#{id}/download-protected", query: query) do
      {:ok, %Tesla.Env{body: pdf_bytes}} ->
        {:ok, pdf_bytes}

      error ->
        format_error(error)
    end
  end

  @doc """
  Delete a document.

  ## Examples

  iex> PandaDoc.delete_document("msFYActMfJHqNTKH8YSvF1")
  :ok

  """
  def delete_document(id) do
    case delete("/documents/#{id}") do
      {:ok, %Tesla.Env{status: 204}} ->
        :ok

      error ->
        format_error(error)
    end
  end

  @doc """
  List documents, optionally filter by a search query or tags.

  ## Examples

  iex> PandaDoc.list_documents()
  {:ok,
    [
      %{
        id: "msFYActMfJHqNTKH8YSvF1",
        name: "Sample Document",
        status: "document.draft",
        date_created: "2017-08-06T08:42:13.836022Z",
        date_modified: "2017-09-04T02:21:13.963750Z",
        expiration_date: nil,
        version: "1"
      }
    ]
  }

  """
  def list_documents(query \\ []) do
    case get("/documents", query: query) do
      {:ok, %Tesla.Env{body: %{results: results}}} ->
        {:ok, results}

      error ->
        format_error(error)
    end
  end
end
