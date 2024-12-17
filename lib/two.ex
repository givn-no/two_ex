defmodule Two do
  @moduledoc """
  Root module for creating clients.
  """

  alias Two.Types

  @default_adapter Tesla.Adapter.Httpc

  @test_base_url "https://sandbox.api.two.inc/v1"
  @production_base_url "https://api.two.inc/v1"

  defp base_url(:test), do: @test_base_url
  defp base_url(:production), do: @production_base_url

  @type adapter_option :: {:adapter, {Tesla.Client.adapter(), []}, Tesla.Client.adapter() | nil}
  @type middleware_option :: {:middleware, [Tesla.Client.middleware()] | nil}
  @type two_option :: adapter_option() | middleware_option()
  @type two_options :: [two_option()]

  @doc """
  Initializes a Tesla http client.
  """
  @spec new(:test | :production, String.t(), two_options()) :: Tesla.Client.t()
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
        Tesla.Middleware.JSON
      ] ++
        additional_middleware ++
        [
          # Run PathParams after additional_middleware in order to
          # support e.g. metrics, etc. on the parameterized URL
          Tesla.Middleware.PathParams,
          Tesla.Middleware.Logger
        ]

    Tesla.client(middleware, adapter)
  end

  @doc """
  Initializes a Tesla http client.

  This function reads parameters from config and calls `new/3`
  """
  @spec new() :: Tesla.Client.t()
  def new() do
    env = Application.fetch_env!(:two_ex, :env)
    api_key = Application.fetch_env!(:two_ex, :api_key)
    adapter = Application.fetch_env!(:two_ex, :adapter)
    middleware = Application.fetch_env!(:two_ex, :middleware)
    new(env, api_key, adapter: adapter, middleware: middleware)
  end

  @spec with_retry_middleware(Tesla.Client.t()) :: Tesla.Client.t()
  defp with_retry_middleware(client) do
    retry_middleware =
      {Tesla.Middleware.Retry,
       [
         delay: 500,
         max_retries: 3,
         should_retry: fn
           # retry 503
           {:ok, %{status: 503}} -> true
           # don't retry timeouts
           {:error, "timeout"} -> false
           # retry other connection errors
           {:error, _} -> true
           _ -> false
         end
       ]}

    Tesla.client([retry_middleware | Tesla.Client.middleware(client)], Tesla.Client.adapter(client))
  end

  @spec evaluate_response({:ok, %Tesla.Env{}} | {:error, %Tesla.Env{}}) :: {:ok, map() | nil} | {:error, %Tesla.Env{}}
  defp evaluate_response({:error, _} = error), do: error

  defp evaluate_response({:ok, %Tesla.Env{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp evaluate_response({:ok, %Tesla.Env{status: status}}) when status in 200..299 do
    {:ok, nil}
  end

  defp evaluate_response({:ok, %Tesla.Env{status: status, body: body}}) when status in 400..499 do
    {:error, {:http_error, status, body}}
  end

  defp evaluate_response({:ok, %Tesla.Env{status: status}}) when status in 400..499 do
    {:error, {:http_error, status, nil}}
  end

  defp evaluate_response({:ok, %Tesla.Env{status: status} = env}) do
    {:error, {:unhandled_status, status, env}}
  end

  @doc """
  Create an order.
  """
  @spec create_order(Tesla.Env.client(), Types.new_order()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def create_order(client, order) do
    client
    |> with_retry_middleware()
    |> Tesla.post("/order", order)
    |> evaluate_response()
  end

  @doc """
  Create an order.
  """
  @spec create_order_intent(Tesla.Env.client(), Types.new_order_intent()) ::
          {:ok, Types.order_intent()} | {:error, Tesla.Env.t()}
  def create_order_intent(client, order) do
    client
    |> with_retry_middleware()
    |> Tesla.post("/order_intent", order)
    |> evaluate_response()
  end

  @doc """
  Get a previously created order.
  """
  @spec get_order(Tesla.Env.client(), String.t()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def get_order(client, order_id) do
    client
    |> with_retry_middleware()
    |> Tesla.get("/order/:id", opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  Get a previously created order.
  """
  @spec get_order_intent(Tesla.Env.client(), String.t()) :: {:ok, Types.order_intent()} | {:error, Tesla.Env.t()}
  def get_order_intent(client, order_intent_id) do
    client
    |> with_retry_middleware()
    |> Tesla.get("/order_intent/:id", opts: [path_params: [id: order_intent_id]])
    |> evaluate_response()
  end

  @doc """
  List all orders.
  """
  @spec get_orders(Tesla.Env.client()) :: {:ok, [Types.order()]} | {:error, Tesla.Env.t()}
  def get_orders(client) do
    client
    |> with_retry_middleware()
    |> Tesla.get("/orders")
    |> evaluate_response()
  end

  @doc """
  Update an order.
  """
  @spec update_order(Tesla.Env.client(), String.t(), Types.order()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def update_order(client, order_id, order) do
    client
    |> with_retry_middleware()
    |> Tesla.put("/order/:id", order, opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  Refund an order.
  """
  # @spec refund_order(Tesla.Env.client(), String.t(), Types.refund_req()) :: {:ok, Types.order()} | {:error, Tesla.Env.t()}
  def refund_order(client, order_id, refund) do
    Tesla.post(client, "/order/:id/refund", refund, opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  Cancel an order and void the invoice.
  """
  @spec cancel_order(Tesla.Env.client(), String.t()) :: {:ok, :order_cancelled} | {:error, Tesla.Env.t()}
  def cancel_order(client, order_id) do
    client
    |> with_retry_middleware()
    |> Tesla.post("/order/:id/cancel", nil, opts: [path_params: [id: order_id]])
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
    client
    |> with_retry_middleware()
    |> Tesla.post("/order/:id/delivered", "", opts: [path_params: [id: order_id]])
    |> evaluate_response()
    |> case do
      {:ok, _} -> {:ok, :order_delivered}
      other -> other
    end
  end

  @doc """
  Set order state `FULFILLED`.

  The endpoint supports partial fulfillment, but it is not implemented here (for now).
  """
  @spec fulfill_order(Tesla.Env.client(), String.t(), keyword()) :: {:ok, :order_fulfilled} | {:error, Tesla.Env.t()}
  def fulfill_order(client, order_id, opts \\ []) do
    query =
      case Enum.into(opts, %{}) do
        %{lang: lang} -> [lang: lang]
        _ -> []
      end

    client
    |> with_retry_middleware()
    |> Tesla.post("/order/:id/fulfillments", "", query: query, opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @doc """
  Get verification information for an order.
  """
  @spec get_order_verification(Tesla.Env.client(), String.t()) ::
          {:ok, Types.order_verification()} | {:error, Tesla.Env.t()}
  def get_order_verification(client, order_id) do
    client
    |> with_retry_middleware()
    |> Tesla.get("/orders/:id/verification", opts: [path_params: [id: order_id]])
    |> evaluate_response()
  end

  @spec get_company_address(Tesla.Env.client(), String.t(), String.t()) ::
          {:ok, Types.company_address()} | {:error, Tesla.Env.t()}
  def get_company_address(client, country_code, organization_id) do
    client
    |> with_retry_middleware()
    |> Tesla.get("/:country_code/company/:organization_id/address",
      opts: [path_params: [country_code: country_code, organization_id: organization_id]]
    )
    |> evaluate_response()
  end
end
