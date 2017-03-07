defmodule Examples.Topic do
  @behaviour ExRabbit

  def config() do
    [
      name: "topic_name",
      exchange: [
        type: :topic,
        name: "topic_exchange"
      ],
      queue: [
        name: "topic_queue",
        options: [
          durable: true,
          arguments: [
            {"x-dead-letter-exchange", "dead-letter"},
          ]
        ]
      ],
      binding_options: [
        routing_key: "the_topic"
      ],
      parse_json: true
    ]
  end

  def handler(_msg, _meta) do
    {:ok, []}
  end
end
