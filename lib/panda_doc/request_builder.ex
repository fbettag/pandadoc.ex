defmodule PandaDoc.RequestBuilder do
  @moduledoc """
  Helper functions for building Tesla requests
  """

  @doc """
  Specify the request method when building a request

  ## Parameters

  - request (Map) - Collected request options
  - m (atom) - Request method

  ## Returns

  Map
  """
  @spec method(map(), atom) :: map()
  def method(request, m) do
    Map.put_new(request, :method, m)
  end

  @doc """
  Specify the request method when building a request

  ## Parameters

  - request (Map) - Collected request options
  - u (String) - Request URL

  ## Returns

  Map
  """
  @spec url(map(), String.t()) :: map()
  def url(request, u) do
    Map.put_new(request, :url, u)
  end

  @doc """
  Add optional parameters to the request

  ## Parameters

  - request (Map) - Collected request options
  - definitions (Map) - Map of parameter name to parameter location.
  - options (KeywordList) - The provided optional parameters

  ## Returns

  Map
  """
  @spec add_optional_params(map(), %{optional(atom) => atom}, keyword()) :: map()
  def add_optional_params(request, _, []), do: request

  def add_optional_params(request, definitions, [{key, value} | tail]) do
    case definitions do
      %{^key => location} ->
        request
        |> add_param(location, key, value)
        |> add_optional_params(definitions, tail)

      _ ->
        add_optional_params(request, definitions, tail)
    end
  end

  @doc """
  Add optional parameters to the request

  ## Parameters

  - request (Map) - Collected request options
  - location (atom) - Where to put the parameter
  - key (atom) - The name of the parameter
  - value (any) - The value of the parameter

  ## Returns

  Map
  """
  @spec add_param(map(), atom, atom, any()) :: map()
  def add_param(request, :body, :body, value), do: Map.put(request, :body, value)

  def add_param(request, :body, key, value) do
    request
    |> Map.put_new_lazy(:body, &Tesla.Multipart.new/0)
    |> Map.update!(
      :body,
      &Tesla.Multipart.add_field(&1, key, Poison.encode!(value),
        headers: [{"content-type", "application/json"}]
      )
    )
  end

  def add_param(request, :headers, key, value) do
    request
    |> Tesla.put_header(key, value)
  end

  def add_param(request, :file, name, path) do
    request
    |> Map.put_new_lazy(:body, &Tesla.Multipart.new/0)
    |> Map.update!(:body, &Tesla.Multipart.add_file(&1, path, name: name))
  end

  def add_param(request, :form, name, value) do
    request
    |> Map.update(:body, %{name => value}, &Map.put(&1, name, value))
  end

  def add_param(request, location, key, value) do
    Map.update(request, location, [{key, value}], &(&1 ++ [{key, value}]))
  end

  @doc """
  Handle the response for a Tesla request

  ## Parameters

  - arg1 (Tesla.Env.t | term) - The response object
  - arg2 (:false | struct | [struct]) - The shape of the struct to deserialize into

  ## Returns

  `{:ok, struct()}` on success
  `{:ok, Tesla.Env.t()}` on failure
  `{:error, term}` on failure
  """
  @spec decode(Tesla.Env.t() | term(), false | struct() | [struct()]) ::
          {:ok, struct()} | {:ok, Tesla.Env.t()} | {:error, any}
  def decode(%Tesla.Env{} = env, false), do: {:ok, env}
  def decode(%Tesla.Env{}, :ok), do: :ok
  def decode(%Tesla.Env{body: body}, :bytes), do: {:ok, body}
  def decode(%Tesla.Env{body: body}, struct), do: Poison.decode(body, as: struct)

  @doc """
  Evaluates the Tesla response

  ## Parameters

  - arg1 {:atom, Tesla.Env.t} - The response object
  - arg2 list - List of Tuples matching something like [{200, %Model.ErrorResponse{}}]

  ## Returns

  `{:ok, struct}` on success
  `{:ok, Tesla.Env.t()}` on failure
  `{:error, term}` on failure
  """
  @spec evaluate_response({:error, any()} | {:atom, Tesla.Env.t()}, list()) ::
          {:ok, struct()} | {:ok, Tesla.Env.t()} | {:error, any}
  def evaluate_response({:ok, %Tesla.Env{} = env}, mapping) do
    resolve_mapping(env, mapping)
  end

  def evaluate_response({:error, _} = error, _), do: error

  defp resolve_mapping(env, mapping, default \\ nil)

  defp resolve_mapping(%Tesla.Env{status: status} = env, [{mapping_status, struct} | _], _)
       when status == mapping_status do
    decode(env, struct)
  end

  defp resolve_mapping(env, [{:default, struct} | tail], _),
    do: resolve_mapping(env, tail, struct)

  defp resolve_mapping(env, [_ | tail], struct), do: resolve_mapping(env, tail, struct)
  defp resolve_mapping(env, [], nil), do: {:error, env}
  defp resolve_mapping(env, [], struct), do: decode(env, struct)
end
