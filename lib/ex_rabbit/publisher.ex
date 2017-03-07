defmodule ExRabbit.Publisher do
  use Supervisor
  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(size) do
    children = 1..size
      |> Enum.to_list
      |> Enum.map(fn(num) -> worker(ExRabbit.Publisher.Worker, [num], id: num) end)

    supervise(children, strategy: :one_for_one)
  end

  def publish(_exchange, _routing_key, _payload, options \\ [])
  def publish(exchange, routing_key, payload, options)
  when not is_bitstring(payload)
  do
    {:ok, encoded_payload} = Poison.encode(payload)
    publish(exchange, routing_key, encoded_payload, options)
  end

  def publish(exchange, routing_key, payload, options) do
    pool_size = Application.get_env(:ex_rabbit, :pool_size)
    num = Enum.random(1..pool_size)
    channel = GenServer.call(:"#{ExRabbit.Publisher.Worker}_#{num}", :get)
    AMQP.Basic.publish(channel, exchange, routing_key, payload, options)
  end
end
