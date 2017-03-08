defmodule ExRabbit do
  @moduledoc """
    ExRabbit is a module that conveniently manages your connection to RabbitMQ and its channels for you.

    It keeps a channel for each consumer and a channel pool for you to publish with. All you need to do is define a
    module that implements the behaviour defined in `ExRabbit`, `config/0` and `handler/2`. Most of the options in
    `config/0` are passed through to the AMQP module for exchange, queue, binding and qos assertions.

    `config/0` and `handler/2` are called by `ExRabbit.Consumer.Consumer` when a message is being consumed. Examples can
    be found in the examples directory.
  """

  @doc """
    This function must be implemented to provide a custom configuration. Example configurations can be found in the
    examples directory.
  """
  @callback config() :: {:ok, list()} | {:error, String.t}

  @doc """
    This function must be implemented to handle a message that is consumed off of a queue. It should return an
    `{:ok, result}` tuple with a list of keyword lists indicating any new messages to publish. Alternatively, it can
    return an `{:error, reason}` tuple with a reason.
  """
  @callback handler(Map, Map) :: {:ok, list(keyword())} | {:error, String.t}

  @doc """
    Publish a message to an exchange. Possible options are available from:
    https://github.com/pma/amqp/blob/master/lib/amqp/basic.ex
  """
  @spec publish(String.t, String.t, map() | String.t, keyword()) :: :ok
  def publish(exchange, routing_key, payload, options \\ [])
  def publish(exchange, routing_key, payload, options),
  do: ExRabbit.Publisher.publish(exchange, routing_key, payload, options)
end
