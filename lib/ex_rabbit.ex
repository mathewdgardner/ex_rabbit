defmodule ExRabbit do
  @callback config() :: {:ok, List.t} | {:error, String.t}
  @callback handler(Map, Map) :: {:ok, List.t} | {:error, String.t}

  def publish(exchange, routing_key, payload, options), do: ExRabbit.Publisher.publish(exchange, routing_key, payload, options)
end
