defmodule PandaDoc.PhoenixController do
  @moduledoc """
  Implements a PhoenixController that can be easily wired up and used.

  ## Examples

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

  """

  @doc """
  Triggers when a PandaDoc document changed.
  """
  @callback handle_document_change(String.t(), String.t(), map()) :: any()

  @doc """
  Triggers when a PandaDoc document has been completed/signed.
  """
  @callback handle_document_complete(String.t(), binary(), String.t(), map()) :: any()

  defmacro __using__(_) do
    quote do
      @moduledoc "Implements a PhoenixController with callbacks for PandaDoc."
      @behaviour PandaDoc.PhoenixController
      require Logger
      use Phoenix.Controller
      alias Plug.Conn

      @doc "default webhook that should match."
      @spec webhook(Conn.t(), map()) :: Conn.t()
      def webhook(conn, %{"_json" => data}) do
        Enum.each(data, &parse_document/1)
        Conn.send_resp(conn, 200, "")
      end

      @doc "fallback webhook that should not match."
      @spec webhook(Conn.t(), map()) :: Conn.t()
      def webhook(conn, _), do: Conn.send_resp(conn, 406, "")

      # parsing valid document state changes
      defp parse_document(%{
             "event" => "document_state_changed",
             "data" =>
               %{
                 "id" => id,
                 "status" => status
               } = details
           }) do
        spawn(fn ->
          case status do
            "document.completed" ->
              pdf = download_data(id)
              handle_document_complete(id, pdf, status, details)

            _ ->
              handle_document_change(id, status, details)
          end
        end)
      end

      # failsafe for parsing bad documents
      defp parse_document(_), do: :ok

      # downloads the document from pandadoc
      defp download_data(id) do
        if Mix.env() == :test do
          # no way of testing the pandadoc api programatically
          Logger.info("[PandaDoc] Using dummy data for tests")
          :crypto.strong_rand_bytes(128)
        else
          # we wait here since PandaDoc is not the fastest
          Logger.info("[PandaDoc] Downloading document #{id} in 30 seconds")
          :timer.sleep(30_000)

          id
          |> PandaDoc.download_document()
          |> ok_data(id)
        end
      end

      # just returns the pdf document
      defp ok_data({:ok, pdf}, id) do
        Logger.info("[PandaDoc] Successfully downloaded document #{id}")
        pdf
      end

      # retries the request in 2 seconds
      defp ok_data({:error, error}, id) do
        Logger.info(
          "[PandaDoc] Retrying download of document #{id} in 2 seconds: #{inspect(error)}"
        )

        :timer.sleep(2_000)
        download_data(id)
      end
    end
  end
end
