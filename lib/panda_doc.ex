defmodule PandaDoc do
  @moduledoc """
  Documentation for `PandaDoc` which provides an API for pandadoc.com.

  ## Installation

  This package can be installed by adding `pandadoc` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:pandadoc, "~> 0.1.2"}
    ]
  end
  ```

  ## Configuration

  Put the following lines into your `config.exs` or better, into your environment configuration files like `test.exs`, `dev.exs` or `prod.exs.`.

  ```elixir
  config :pandadoc, api_key: "<your api key>"
  ```

  ## WebHooks in Phoenix

  Put the following lines in a file called `pandadoc_controller.ex` inside your controllers directory.

  ```elixir
  defmodule YourAppWeb.PandaDocController do
    use PandaDoc.PhoenixController

    def handle_document_change(id, status, _details) do
      id
      |> Documents.get_by_pandadoc_id!()
      |> Documents.update_document(%{status: status})
    end

    def handle_document_complete(id, pdf, status, _details) do
      id
      |> Documents.get_by_pandadoc_id!()
      |> Documents.update_document(%{data: pdf, status: status})
    end
  end
  ```

  Put the following lines into your `router.ex` and configure the WebHook in the pandadoc portal.

  ```elixir
    post "/callbacks/pandadoc", YourAppWeb.PandaDocController, :webhook
  ```

  ## Usage

      iex> recipients = [
        %PandaDoc.Recipient{
          email: "jane@example.com",
          first_name: "Jane",
          last_name: "Example",
          role: "signer1"
        }
      ]

      iex> PandaDoc.create_document("Sample PandaDoc PDF.pdf", [] = pdf_bytes, recipients)
      {:ok, "msFYActMfJHqNTKH8YSvF1"}


  """
  import PandaDoc.RequestBuilder
  alias PandaDoc.Connection
  alias PandaDoc.Model
  alias Tesla.Multipart

  @doc """
  Creates a new Document from the given PDF file.

  ## Examples

      iex> pdf_bytes = File.read("/path/to/my.pdf")
      iex> recipients = [
        %PandaDoc.Model.Recipient{email: "jane@example.com", first_name: "Jane", last_name: "Example", role: "signer1"}
      ]
      iex> fields = %{
        name: %PandaDoc.Model.Field{value: "John", role: "signer1"}
      }
      iex> PandaDoc.create_document("Sample PandaDoc PDF.pdf", pdf_bytes, recipients, fields, ["tag1"])
      {:ok, "msFYActMfJHqNTKH8YSvF1"}

  """
  @spec create_document(
          String.t(),
          binary(),
          list(Model.Recipient.t()),
          map() | nil,
          list(String.t()) | nil,
          boolean() | nil,
          Tesla.Env.client() | nil
        ) ::
          {:ok, String.t()}
          | {:ok, Model.BasicDocumentResponse.t()}
          | {:ok, Model.ErrorResponse.t()}
          | {:error, Tesla.Env.t()}
  def create_document(
        name,
        pdf_bytes,
        recipients,
        fields \\ %{},
        tags \\ [],
        parse_form_fields \\ false,
        client \\ Connection.new()
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

    with {:ok, %Model.BasicDocumentResponse{id: id}} <-
           %{}
           |> method(:post)
           |> url("/documents")
           |> add_param(:body, :body, mp)
           |> Enum.into([])
           |> (&Tesla.request(client, &1)).()
           |> evaluate_response([
             {201, %Model.BasicDocumentResponse{}},
             {400, %Model.ErrorResponse{}},
             {403, %Model.ErrorResponse{}},
             {500, %Model.ErrorResponse{}}
           ]) do
      {:ok, id}
    end
  end

  @doc """
  Move a document to sent status and send an optional email.

  ## Examples

      iex> PandaDoc.send_document("msFYActMfJHqNTKH8YSvF1", "Document ready", "Hi there, please sign this document")
      {:ok, %PandaDoc.Model.BasicDocumentResponse{id: "msFYActMfJHqNTKH8YSvF1", status: "document.sent"}}

  """
  @spec send_document(
          String.t(),
          String.t() | nil,
          String.t() | nil,
          boolean() | nil,
          Tesla.Env.client() | nil
        ) ::
          {:ok, Model.BasicDocumentResponse.t()}
          | {:ok, Model.ErrorResponse.t()}
          | {:error, Tesla.Env.t()}
  def send_document(
        id,
        subject \\ nil,
        message \\ nil,
        silent \\ false,
        client \\ Connection.new()
      ) do
    json = %{
      subject: subject,
      message: message,
      silent: silent
    }

    %{}
    |> method(:post)
    |> url("/documents/#{id}/send")
    |> add_param(:body, :body, json)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {200, %Model.BasicDocumentResponse{}}
    ])
  end

  @doc """
  Get basic data about a document such as name, status, and dates.

  ## Examples

      iex> PandaDoc.document_status("msFYActMfJHqNTKH8YSvF1")
      {:ok, %PandaDoc.Model.BasicDocumentResponse{id: "msFYActMfJHqNTKH8YSvF1", status: "document.waiting_approval"}}

  """
  @spec document_status(String.t(), Tesla.Env.client() | nil) ::
          {:ok, Model.BasicDocumentResponse.t()}
          | {:ok, Model.ErrorResponse.t()}
          | {:error, Tesla.Env.t()}
  def document_status(id, client \\ Connection.new()) do
    %{}
    |> method(:get)
    |> url("/documents/#{id}")
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {200, %Model.BasicDocumentResponse{}},
      {400, %Model.ErrorResponse{}},
      {403, %Model.ErrorResponse{}},
      {404, %Model.ErrorResponse{}},
      {500, %Model.ErrorResponse{}}
    ])
  end

  @doc """
  Get detailed data about a document such as name, status, dates, fields, metadata and much more.

  ## Examples

      iex> PandaDoc.document_details("msFYActMfJHqNTKH8YSvF1")
      {:ok, %PandaDoc.Model.DocumentResponse{id: "msFYActMfJHqNTKH8YSvF1", status: "document.waiting_approval"}}

  """
  @spec document_details(String.t(), Tesla.Env.client() | nil) ::
          {:ok, Model.DocumentResponse.t()}
          | {:ok, Model.ErrorResponse.t()}
          | {:error, Tesla.Env.t()}
  def document_details(id, client \\ Connection.new()) do
    %{}
    |> method(:get)
    |> url("/documents/#{id}/details")
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {200, %Model.DocumentResponse{}},
      {400, %Model.ErrorResponse{}},
      {403, %Model.ErrorResponse{}},
      {404, %Model.ErrorResponse{}},
      {500, %Model.ErrorResponse{}}
    ])
  end

  @doc """
  Generates a link for the given recipient that you can just email or iframe with a validity of `lifetime` seconds (86400 by default).

  ## Examples

      iex> PandaDoc.share_document("msFYActMfJHqNTKH8YSvF1", "jane@example.com", 900)
      {:ok, "https://app.pandadoc.com/s/msFYActMfJHqNTKH8YSvF1", expires_at: ~U[2017-08-29T22:18:44.315Z]}

  """
  @spec share_document(String.t(), String.t(), integer() | nil, Tesla.Env.client() | nil) ::
          {:ok, String.t(), DateTime.t()}
          | {:ok, Model.ErrorResponse.t()}
          | {:error, Tesla.Env.t()}
  def share_document(id, recipient_email, lifetime \\ 86_400, client \\ Connection.new()) do
    json = %{
      recipient: recipient_email,
      lifetime: lifetime
    }

    with {:ok, %Model.BasicDocumentResponse{id: share_id, expires_at: expires_at}} <-
           %{}
           |> method(:post)
           |> url("/documents/#{id}/session")
           |> add_param(:body, :body, json)
           |> Enum.into([])
           |> (&Tesla.request(client, &1)).()
           |> evaluate_response([
             {201, %Model.BasicDocumentResponse{}},
             {400, %Model.ErrorResponse{}},
             {403, %Model.ErrorResponse{}},
             {404, %Model.ErrorResponse{}},
             {500, %Model.ErrorResponse{}}
           ]) do
      {:ok, "https://app.pandadoc.com/s/#{share_id}", expires_at}
    end
  end

  @doc """
  Download a PDF of any document.

  ## Examples

      iex> PandaDoc.download_document("msFYActMfJHqNTKH8YSvF1", watermark_text: "WATERMARKED")
      {:ok, []}

  """
  @spec download_document(String.t(), keyword(String.t()) | nil, Tesla.Env.client() | nil) ::
          {:ok, binary()} | {:ok, Model.ErrorResponse.t()} | {:error, Tesla.Env.t()}
  def download_document(id, query \\ [], client \\ Connection.new()) do
    optional_params = %{
      :watermark_text => :query,
      :watermark_color => :query,
      :watermark_font_size => :query,
      :watermark_opacity => :query
    }

    %{}
    |> method(:get)
    |> url("/documents/#{id}/download")
    |> add_optional_params(optional_params, query)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {200, :bytes},
      {400, %Model.ErrorResponse{}},
      {403, %Model.ErrorResponse{}},
      {404, %Model.ErrorResponse{}},
      {500, %Model.ErrorResponse{}}
    ])
  end

  @doc """
  Download a signed PDF of a completed document.

  ## Examples

      iex> PandaDoc.download_protected_document("msFYActMfJHqNTKH8YSvF1")
      {:ok, []}

  """
  @spec download_protected_document(
          String.t(),
          keyword(String.t()) | nil,
          Tesla.Env.client() | nil
        ) ::
          {:ok, binary()} | {:ok, Model.ErrorResponse.t()} | {:error, Tesla.Env.t()}
  def download_protected_document(id, query \\ [], client \\ Connection.new()) do
    optional_params = %{
      :hard_copy_type => :query
    }

    %{}
    |> method(:get)
    |> url("/documents/#{id}/download-protected")
    |> add_optional_params(optional_params, query)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {200, :bytes},
      {400, %Model.ErrorResponse{}},
      {403, %Model.ErrorResponse{}},
      {404, %Model.ErrorResponse{}},
      {500, %Model.ErrorResponse{}}
    ])
  end

  @doc """
  Delete a document.

  ## Examples

      iex> PandaDoc.delete_document("msFYActMfJHqNTKH8YSvF1")
      :ok

  """
  @spec delete_document(String.t(), Tesla.Env.client() | nil) ::
          {:ok, :atom} | {:ok, Model.ErrorResponse.t()} | {:error, Tesla.Env.t()}
  def delete_document(id, client \\ Connection.new()) do
    %{}
    |> method(:delete)
    |> url("/documents/#{id}")
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {204, :ok},
      {400, %Model.ErrorResponse{}},
      {403, %Model.ErrorResponse{}},
      {404, %Model.ErrorResponse{}},
      {500, %Model.ErrorResponse{}}
    ])
  end

  @doc """
  List documents, optionally filter by a search query or tags.

  ## Examples

      iex> PandaDoc.list_documents()
      {:ok, %Model.DocumentListResponse{results: [%Model.BasicDocumentResponse{}]}}

  """
  @spec list_documents(keyword(String.t()) | nil, Tesla.Env.client() | nil) ::
          {:ok, Model.DocumentListResponse.t()}
          | {:ok, Model.ErrorResponse.t()}
          | {:error, Tesla.Env.t()}
  def list_documents(query \\ [], client \\ Connection.new()) do
    optional_params = %{
      :q => :query,
      :tag => :query,
      :status => :query,
      :count => :query,
      :page => :query,
      :deleted => :query,
      :id => :query,
      :template_id => :query,
      :folder_uuid => :query
    }

    %{}
    |> method(:get)
    |> url("/documents")
    |> add_optional_params(optional_params, query)
    |> Enum.into([])
    |> (&Tesla.request(client, &1)).()
    |> evaluate_response([
      {200, %Model.DocumentListResponse{}},
      {400, %Model.ErrorResponse{}},
      {403, %Model.ErrorResponse{}},
      {404, %Model.ErrorResponse{}},
      {500, %Model.ErrorResponse{}}
    ])
  end
end
