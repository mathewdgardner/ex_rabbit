defmodule Examples.Error do
  @behaviour ExRabbit

  def config() do
    [
      name: "topic_name",
      exchange: [
        type: :topic,
        name: "topic_exchange"
      ],
      queue: [
        name: "error_topic_queue",
        options: [
          durable: true,
          arguments: [
            {"x-dead-letter-exchange", "dead-letter"},
          ]
        ]
      ],
      binding_options: [
        routing_key: "error_topic"
      ],
      parse_json: true
    ]
  end

  def handler(_msg, _meta) do
    {:error, "Made up reason"}
  end
end
