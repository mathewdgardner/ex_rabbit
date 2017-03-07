defmodule Examples.FullOptions do
  @behaviour ExRabbit

  def config() do
    [
      name: "rabbit_name",
      exchange: "my_exchange",
      topic: "the_topic",
      queue: [
        name: "my_queue",
        options: [
          durable: true,
          arguments: [
            {"x-expires", ""},
            {"x-message-ttl", ""},
            {"x-dead-letter-routing-key", ""},
            {"x-dead-letter-exchange", ""},
            {"x-max-length", ""},
            {"x-max-length-bytes", ""}
          ]
        ]
      ]
    ]
  end

  def handler(_msg, _meta) do
    {:ok, []}
  end
end
