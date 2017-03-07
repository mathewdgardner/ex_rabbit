defmodule ExRabbit.PublisherSpec do
  use ESpec

  describe "ExRabbit.Publisher" do
    it "should publish to a topic" do
      channel = :sys.get_state(ExRabbit.Publisher.Worker_1)
      exchange = "test_topic_exchange"
      queue = "test_queue"
      routing_key = "test"
      payload = %{foo: :bar}

      {:ok, _} = AMQP.Queue.declare(channel, queue)
      :ok      = AMQP.Exchange.declare(channel, exchange, :topic)
      :ok      = AMQP.Queue.bind(channel, queue, exchange, [routing_key: routing_key])

      before_count = Helpers.Amqp.get_messages!(queue)
        |> length

      ExRabbit.Publisher.publish(exchange, routing_key, payload)
      after_count = Helpers.Amqp.get_messages!(queue)
        |> length

      expect after_count |> to(eql(before_count + 1))
    end

    it "should publish with an ecoded payload" do
      channel = :sys.get_state(ExRabbit.Publisher.Worker_1)
      exchange = "test_topic_exchange"
      queue = "test_queue"
      routing_key = "test"
      payload = %{foo: :bar} |> Poison.encode!

      {:ok, _} = AMQP.Queue.declare(channel, queue)
      :ok      = AMQP.Exchange.declare(channel, exchange, :topic)
      :ok      = AMQP.Queue.bind(channel, queue, exchange, [routing_key: routing_key])

      before_count = Helpers.Amqp.get_messages!(queue)
        |> length

      ExRabbit.Publisher.publish(exchange, routing_key, payload)
      after_count = Helpers.Amqp.get_messages!(queue)
        |> length

      expect after_count |> to(eql(before_count + 1))
    end
  end
end
