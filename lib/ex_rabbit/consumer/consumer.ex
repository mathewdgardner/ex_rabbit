defmodule ExRabbit.Consumer.Consumer do
  @moduledoc """
  `GenServer` to consume messages from a queue.

  It keeps its own `AMQP.Channel` for consumption. Message acknowledgement and rejection is handled here.
  """

  alias ExRabbit.Consumer.WorkerSupervisor
  require Logger
  use AMQP
  use GenServer

  # Default configuration options.
  @config [
    consumer_name: "ex_rabbit_consumer",
    exchange: [
      type: :topic,
      name: "ex_rabbit_exchange",
      options: [
        durable: true,
        arguments: []
      ]
    ],
    queue: [
      name: nil,
      options: [
        durable: true,
        arguments: []
      ]
    ],
    binding_options: [
      routing_key: ""
    ],
    consume_options: [
      consumer_tag: __MODULE__
    ],
    qos_options: [
      prefetch_count: Application.get_env(:ex_rabbit, :prefetch_count, 4)
    ],
    parse_json: true
  ]

  def start_link(module) do
    GenServer.start_link(__MODULE__, module, name: ExRabbit.Application.via({__MODULE__, module}))
  end

  def init(module) do
    with {:ok, channel} <- open_channel(),
         config         <- Keyword.merge(@config, module.config()),
         {:ok, _ctag}   <- setup(channel, config)
    do
      {:ok, %{channel: channel, config: config}}
    else
      err -> Logger.error("[#{__MODULE__}] Error settuping up consumer. #{inspect err}")
    end
  end

  # AMQP.Basic.consume callbacks

  def handle_info({:basic_deliver, payload, meta}, state) do
    Logger.debug("[#{__MODULE__}] Received message: #{payload}.")

    WorkerSupervisor.handle_message(payload, meta, self())
    {:noreply, state}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: ctag}}, state) do
    Logger.info("[#{__MODULE__}] Successfully registered consumer as #{ctag}")

    {:noreply, state}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _ctag, no_wait: _no_wait}}, state), do: {:stop, :normal, state}
  def handle_info({:basic_cancel_ok, %{consumer_tag: _ctag}}, state), do: {:noreply, state}

  # ExRabbit.Consumer.Worker callbacks

  def handle_cast({:ack, %{meta: %{delivery_tag: dtag}}}, %{channel: channel} = state) do
    Logger.debug("[#{__MODULE__}] Acknowledging message.")

    Basic.ack(channel, dtag)
    {:noreply, state}
  end

  def handle_cast({:reject, %{meta: %{delivery_tag: dtag}}}, %{channel: channel} = state) do
    Logger.debug("[#{__MODULE__}] Rejecting message.")

    Basic.reject(channel, dtag, [requeue: false])
    {:noreply, state}
  end

  # Private

  # Calls for a connection to RabbitMQ, then opens a channel on the connection. If a channel fails to open, it will
  # retry.
  @spec open_channel() :: {:ok, Channel.t}
  defp open_channel() do
    connection = GenServer.call(ExRabbit.Connection, :get)

    case Channel.open(connection) do
      {:ok, channel} ->
        {:ok, channel}
      {:error, reason} ->
        Logger.error("[#{__MODULE__}] Error opening a channel: #{reason}. Waiting to try again...")

        :timer.sleep(Application.get_env(:ex_rabbit, :backoff))
        open_channel()
    end
  end

  # Asserts the exchange, queue, binding, qos according to the given consumer module's config/0 output and begins
  # consuming.
  @spec setup(Channel.t, keyword()) :: {:ok, String.t}
  defp setup(channel, config) do
    with consumer_name      <- Keyword.get(config, :consumer_name),
         exchange           <- Keyword.get(config, :exchange),
         exchange_name      <- Keyword.get(exchange, :name),
         exchange_type      <- Keyword.get(exchange, :type),
         exchange_options   <- Keyword.get(exchange, :options),
         queue              <- Keyword.get(config, :queue),
         queue_options      <- Keyword.get(queue, :options),
         binding_options    <- Keyword.get(config, :binding_options),
         consume_options    <- Keyword.get(config, :consume_options),
         qos_options        <- Keyword.get(config, :qos_options),
         queue_name         <- get_queue_name(queue, exchange_name, consumer_name),
         {:ok, _}           <- Queue.declare(channel, queue_name, queue_options),
         :ok                <- Exchange.declare(channel, exchange_name, exchange_type, exchange_options),
         :ok                <- Queue.bind(channel, queue_name, exchange_name, binding_options),
         :ok                <- Basic.qos(channel, qos_options)
    do
      {:ok, ctag} = Basic.consume(channel, queue_name, self(), consume_options)
      Logger.info("[#{__MODULE__}] AMQP channel open for consumer #{ctag}.")
      {:ok, ctag}
    else
      err -> Logger.error("[#{__MODULE__}] Error opening channel. #{inspect err}")
    end
  end

  # Get the queue name given or build a default. The default pattern is <exchange>-<service>-<consumer>
  @spec get_queue_name(keyword(), String.t, String.t) :: String.t
  defp get_queue_name(queue, exchange_name, consumer_name) do
    case Keyword.get(queue, :name) do
      nil ->
        service_name = Application.get_env(:ex_rabbit, :service_name, "ex_rabbit")
        "#{exchange_name}-#{service_name}-#{consumer_name}"

      name -> name
    end
  end
end
