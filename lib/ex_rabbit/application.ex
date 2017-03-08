defmodule ExRabbit.Application do
  @moduledoc """
  The root of the `ExRabbit` supervistion tree.

  It supervises:

  * `ExRabbit.Connection` - A `GenServer` whose state is a connection to RabbitMQ
  * `Registry` - A registry for the application to keep track of worker pids
  * `ExRabbit.Consumer` - A `Supervisor` to manage consumers
  * `ExRabbit.Consumer.WorkerSupervisor` - A `Supervisor` that spawns `GenServer`s to handle messages from a
      consumer
  * `ExRabbit.Publisher` - A `Supervisor` to manage a channel pool
  """

  import Supervisor.Spec
  require Logger
  use Application

  def start(_type, _args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(ExRabbit.Connection, []),
      supervisor(Registry, [:unique, :ex_rabbit_registry]),
      supervisor(ExRabbit.Consumer, [Application.get_env(:ex_rabbit, :modules)]),
      supervisor(ExRabbit.Consumer.WorkerSupervisor, []),
      supervisor(ExRabbit.Publisher, [Application.get_env(:ex_rabbit, :pool_size)])
    ]

    supervise(children, strategy: :one_for_all)
  end

  @doc """
  Returns the `:via` tuple for use with the Registry.
  """
  @spec via(any()) :: {:via, atom(), tuple()}
  def via(name), do: {:via, Registry, {:ex_rabbit_registry, name}}
end
