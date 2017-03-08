defmodule ExRabbit.Consumer.Consumer do
  @moduledoc """
    `GenServer` to consume a queue keeping its own `AMQP.Channel` for consumption.

    Message acknowledgement and rejection is handled here.
  """

  use GenServer
  require Logger

  def start_link(module) do
    GenServer.start_link(__MODULE__, module, name: ExRabbit.Application.via({__MODULE__, module}))
  end

  def init(module) do
    {:ok, channel} = open_channel()

    config = Keyword.merge(config(), module.config())
    setup(channel, config)

    {:ok, %{channel: channel, config: config}}
  end

  # AMQP.Basic.consume callbacks

  def handle_info({:basic_deliver, payload, meta}, state) do
    Logger.debug("[#{__MODULE__}] Received message: #{payload}.")

    ExRabbit.Consumer.WorkerSupervisor.handle_message(payload, meta, self())
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

    AMQP.Basic.ack(channel, dtag)
    {:noreply, state}
  end

  def handle_cast({:reject, %{meta: %{delivery_tag: dtag}}}, %{channel: channel} = state) do
    Logger.debug("[#{__MODULE__}] Rejecting message.")

    AMQP.Basic.reject(channel, dtag, [requeue: false])
    {:noreply, state}
  end

  # Private

  # Calls for a connection to RabbitMQ, then opens a channel on the connection. If a channel fails to open, it will
  # retry.
  @spec open_channel() :: {:ok, AMQP.Channel.t}
  defp open_channel() do
    connection = GenServer.call(ExRabbit.Connection, :get)

    case AMQP.Channel.open(connection) do
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
  @spec setup(AMQP.Channel.t, keyword()) :: {:ok, String.t}
  defp setup(channel, config) do
    with name             <- Keyword.get(config, :name, :ex_rabbit),
         exchange         <- Keyword.get(config, :exchange, []),
         exchange_name    <- Keyword.get(exchange, :name, :ex_rabbit),
         exchange_type    <- Keyword.get(exchange, :type, :topic),
         exchange_options <- Keyword.get(exchange, :options, [durable: true]),
         routing_key      <- Keyword.get(config, :routing_key, ""),
         queue            <- Keyword.get(config, :queue, []),
         queue_name       <- Keyword.get(queue, :name, "#{exchange_name}-#{Application.get_env(:ex_rabbit, :name)}-#{name}"),
         queue_options    <- Keyword.get(queue, :options, [durable: true]),
         binding_options  <- Keyword.get(config, :binding_options, [routing_key: routing_key]),
         consume_options  <- Keyword.get(config, :consume_options, [consumer_tag: __MODULE__]),
         qos_options      <- Keyword.get(config, :qos_options, [prefetch_count: Application.get_env(:ex_rabbit, :prefetch_count)]),
         {:ok, _}         <- AMQP.Queue.declare(channel, queue_name, queue_options),
         :ok              <- AMQP.Exchange.declare(channel, exchange_name, exchange_type, exchange_options),
         :ok              <- AMQP.Queue.bind(channel, queue_name, exchange_name, binding_options),
         :ok              <- AMQP.Basic.qos(channel, qos_options)
    do
      {:ok, ctag} = AMQP.Basic.consume(channel, queue_name, self(), consume_options)
      Logger.info("[#{__MODULE__}] AMQP channel open for consumer #{ctag}.")
      {:ok, ctag}
    else
      err -> Logger.error("[#{__MODULE__}] Error opening channel. #{inspect err}")
    end
  end

  # Default configuration options.
  @spec config() :: keyword()
  defp config() do
    [
      name: "rabbit_name",
      exchange: [
        type: :topic,
        name: "my_exchange",
        options: []
      ],
      routing_key: "the_topic",
      queue: [
        name: "my_queue",
        options: [
          durable: true,
          arguments: []
        ]
      ],
      binding_options: [],
      consume_options: [],
      qos_options: []
    ]
  end
end
