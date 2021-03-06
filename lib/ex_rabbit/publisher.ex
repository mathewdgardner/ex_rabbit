defmodule ExRabbit.Publisher do
  @moduledoc """
  `Supervisor` for managing an channel pool.

  Supervises `ExRabbit.Publisher.Worker` to pool together an `AMQP.Channel` collection.
  """

  use AMQP
  use Supervisor
  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(size) do
    1..size
      |> Enum.map(fn(num) -> worker(ExRabbit.Publisher.Worker, [num], id: num) end)
      |> supervise(strategy: :one_for_one)
  end

  @doc """
  Publish a message to an exchange. An `AMQP.Channel` will be randomly aquired from the pool for use.
  """
  @spec publish(String.t, String.t, map() | String.t, keyword()) :: :ok
  def publish(_exchange, _routing_key, _payload, options \\ [])
  def publish(exchange, routing_key, payload, options)
  when not is_binary(payload)
  do
    {:ok, encoded_payload} = Poison.encode(payload)
    publish(exchange, routing_key, encoded_payload, options)
  end

  def publish(exchange, routing_key, payload, options) do
    pool_size = Application.get_env(:ex_rabbit, :pool_size)

    ExRabbit.Application.via({ExRabbit.Publisher.Worker, Enum.random(1..pool_size)})
      |> GenServer.call(:get)
      |> Basic.publish(exchange, routing_key, payload, options)
  end
end
