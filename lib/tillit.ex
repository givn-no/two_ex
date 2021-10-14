defmodule Tillit do
  @moduledoc """
  Root module for creating clients.
  """

  alias Tillit.Types

  @default_adapter Tesla.Adapter.Httpc

  @test_base_url "https://test.api.tillit.ai/v1"
  @production_base_url "https://api.tillit.ai/v1"

  defp base_url(:test), do: @test_base_url
  defp base_url(:production), do: @production_base_url

  @type adapter_option :: {:adapter, Tesla.Client.adapter() | nil}
  @type middleware_option :: {:middleware, [Tesla.Client.middleware()] | nil}
  @type tillit_option :: adapter_option() | middleware_option()
  @type tillit_options :: [tillit_option()]

  @doc """
  Initializes a Tesla http client.
  """
  @spec new(:test | :production, String.t(), tillit_options()) :: Tesla.Client.t()
  def new(env, api_key, opts \\ []) do
    adapter = opts[:adapter] || @default_adapter
    additional_middleware = opts[:middleware] || []

    middleware =
      [
        {Tesla.Middleware.BaseUrl, base_url(env)},
        {
          Tesla.Middleware.Headers,
          [
            {"user-agent", "Tesla"},
            {"x-api-key", api_key}
          ]
        },
        Tesla.Middleware.JSON,
        Tesla.Middleware.Logger
      ] ++
        additional_middleware ++
        [
          # Always run PathParams as last middleware in order to
          # support metrics, logging, etc. on the parameterized URL
          Tesla.Middleware.PathParams
        ]

    Tesla.client(middleware, adapter)
  end

  @doc """
  Initializes a Tesla http client.

  This function reads parameters from config and calls `new/3`
  """
  @spec new() :: Tesla.Client.t()
  def new() do
    env = Application.fetch_env!(:tillit_ex, :env)
    api_key = Application.fetch_env!(:tillit_ex, :api_key)
    adapter = Application.fetch_env!(:tillit_ex, :adapter)
    middleware = Application.fetch_env!(:tillit_ex, :middleware)
    new(env, api_key, adapter: adapter, middleware: middleware)
  end

  @spec evaluate_response({:ok, %Tesla.Env{}} | {:error, %Tesla.Env{}}) :: {:ok, map() | nil} | {:error, %Tesla.Env{}}
  defp evaluate_response({:error, _} = error), do: error

  defp evaluate_response({:ok, %Tesla.Env{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp evaluate_response({:ok, %Tesla.Env{status: status}}) when status in 200..299 do
    {:ok, nil}
  end

  defp evaluate_response({:ok, %Tesla.Env{status: status}}) do
    {:error, "unhandled http status #{status}"}
  end

  @doc """
  Create an order.
  """
  @spec create_order(Tesla.Env.client(), Types.new_order()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def create_order(client, order) do
    Tesla.post(client, "/order", order)
    |> evaluate_response()
  end

  @doc """
  Create an order.
  """
  @spec create_order_intent(Tesla.Env.client(), Types.new_order_intent()) ::
          {:ok, Types.order_intent()} | {:error, Tesla.Env.t()}
  def create_order_intent(client, order) do
    Tesla.post(client, "/order_intent", order)
    |> evaluate_response()
  end

  @doc """
  Get a previously created order.
  """
  @spec get_order(Tesla.Env.client(), String.t()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def get_order(client, order_id) do
    Tesla.get(client, "/order/:id", opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  Get a previously created order.
  """
  @spec get_order_intent(Tesla.Env.client(), String.t()) :: {:ok, Types.order_intent()} | {:error, Tesla.Env.t()}
  def get_order_intent(client, order_id) do
    Tesla.get(client, "/orders/:id", opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  List all orders.
  """
  @spec get_orders(Tesla.Env.client()) :: {:ok, [Types.order()]} | {:error, Tesla.Env.t()}
  def get_orders(client) do
    Tesla.get(client, "/orders")
    |> evaluate_response()
  end

  @doc """
  Update an order.
  """
  @spec update_order(Tesla.Env.client(), String.t(), Types.order()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def update_order(client, order_id, order) do
    Tesla.put(client, "/order/:id", order, opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  Cancel an order and void the invoice.
  """
  @spec cancel_order(Tesla.Env.client(), String.t()) :: {:ok, :order_cancelled} | {:error, Tesla.Env.t()}
  def cancel_order(client, order_id) do
    Tesla.post(client, "/order/:id/cancel", opts: [path_params: [id: order_id]])
    |> evaluate_response()
    |> case do
      {:ok, _} -> {:ok, :order_cancelled}
      other -> other
    end
  end

  @doc """
  Set order to state `DELIVERED`.
  """
  @spec set_delivered(Tesla.Env.client(), String.t()) :: {:ok, :order_delivered} | {:error, Tesla.Env.t()}
  def set_delivered(client, order_id) do
    Tesla.post(client, "/order/:id/delivered", opts: [path_params: [id: order_id]])
    |> evaluate_response()
    |> case do
      {:ok, _} -> {:ok, :order_delivered}
      other -> other
    end
  end

  @doc """
  Set order state `FULFILLED`.
  """
  @spec set_fulfilled(Tesla.Env.client(), String.t()) :: {:ok, :order_fulfilled} | {:error, Tesla.Env.t()}
  def set_fulfilled(client, order_id) do
    Tesla.post(client, "/order/:id/fulfilled", opts: [path_params: [id: order_id]])
    |> evaluate_response()
    |> case do
      {:ok, _} -> {:ok, :order_fulfilled}
      other -> other
    end
  end

  @doc """
  Get verification information for an order.
  """
  @spec get_order_verification(Tesla.Env.client(), String.t()) ::
          {:ok, Types.order_verification()} | {:error, Tesla.Env.t()}
  def get_order_verification(client, order_id) do
    Tesla.get(client, "/orders/:id/verification", opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end
end
