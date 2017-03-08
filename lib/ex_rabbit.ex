defmodule ExRabbit do
  @moduledoc """
  ExRabbit is a module that conveniently manages your connection to RabbitMQ and its channels for you.

  ## How it works

  For each module given to act as a consumer, it will assert the exchange, queue, binding and qos according to the
  output of the `config/0` callback on your module. Upon each message received your module's `handler/2` callback is
  called providing the message and properties from RabbitMQ. A `AMQP.Channel` is reserved for each consumer in order to
  prevent other consumer/publisher errors from affecting this consumer.

  ## Defining your module

  Your module must implement the `ExRabbit` `@behaviour` as described
  [here](https://hexdocs.pm/elixir/master/Module.html#content).

  ### `config/0`

  This callback must return a keyword list dictating what options to use when setting up the consumer. Examples can be
  found in the [examples](https://github.com/vinli/ex_rabbit/tree/master/examples) directory.

  ### `handler/2`

  This callback must return an `{:ok, result}` or `{:error, reason}` tuple. If an `:ok` tuple is returned the message
  will be acknowledged. Otherwise, if an `:error` tuple is returned, the message will be rejected. This behavior is
  taken care of for you in `ExRabbit.Consumer.Consumer` from where your callback is called.
  """

  @doc """
  This callback must return a keyword list dictating what options to use when setting up the consumer. Examples can be
  found in the [examples](https://github.com/vinli/ex_rabbit/tree/master/examples) directory.
  """
  @callback config() :: {:ok, list()} | {:error, String.t}

  @doc """
  This callback must return an `{:ok, result}` or `{:error, reason}` tuple. If an `:ok` tuple is returned the message
  will be acknowledged. Otherwise, if an `:error` tuple is returned, the message will be rejected. This behavior is
  taken care of for you in `ExRabbit.Consumer.Consumer` from where your callback is called.
  """
  @callback handler(map(), map()) :: {:ok, list(keyword())} | {:error, String.t}

  @doc """
  Publish a message to an exchange. Possible options are available from:
  https://github.com/pma/amqp/blob/master/lib/amqp/basic.ex
  """
  @spec publish(String.t, String.t, map() | String.t, keyword()) :: :ok
  def publish(exchange, routing_key, payload, options \\ [])
  def publish(exchange, routing_key, payload, options),
  do: ExRabbit.Publisher.publish(exchange, routing_key, payload, options)
end
