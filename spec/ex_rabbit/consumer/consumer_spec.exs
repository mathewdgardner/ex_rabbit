defmodule ExRabbit.Consumer.ConsumerSpec do
  use ESpec
  import Mock
  import Helpers.Amqp

  describe "ExRabbit.Consumer.Consumer" do
    it "should open a channel" do
      %{channel: channel} = ExRabbit.Consumer.Consumer.via(Examples.Topic)
        |> :sys.get_state

      expect channel |> to(be_struct AMQP.Channel)
    end

    it "should retry to open a channel" do
      conn = :sys.get_state(ExRabbit.Connection)

      with_mock AMQP.Channel, [open: fn(_conn) -> {:error, "Made up reason"} end] do
        name = ExRabbit.Consumer.Consumer.via(Examples.Topic)
        :ok = GenServer.stop(name)
        :timer.sleep(Application.get_env(:ex_rabbit, :backoff) + 100)

        expect called(AMQP.Channel.open(conn)) |> to(be_true())
      end
    end

    it "should get a new channel on error" do
      name = ExRabbit.Consumer.Consumer.via(Examples.Topic)
      :ok = GenServer.stop(name)
      :timer.sleep(100)
      %{channel: channel} = :sys.get_state(name)

      expect channel |> to(be_struct AMQP.Channel)
    end

    it "should assert the exchange" do
      exchange_name = Examples.Topic.config()[:exchange][:name]
      resp = get_exchange!(exchange_name)

      expect resp["name"] |> to(eql(exchange_name))
    end

    it "should assert a queue" do
      queue_name = Examples.Topic.config()[:queue][:name]
      resp = get_queue!(queue_name)

      expect resp["name"] |> to(eql(queue_name))
    end

    it "should bind a queue to an exchange" do
      exchange_name = Examples.Topic.config()[:exchange][:name]
      queue_name = Examples.Topic.config()[:queue][:name]
      queues = get_bindings!(exchange_name)
        |> Enum.map(fn(binding) -> binding["destination"] end)

      expect queues |> to(have(queue_name))
    end

    it "should consume a message and ack it" do
      exchange = Examples.Topic.config()[:exchange][:name]
      queue = Examples.Topic.config()[:queue][:name]
      routing_key = Examples.Topic.config()[:binding_options][:routing_key]

      publish!(exchange, routing_key, %{foo: :bar})
      :timer.sleep(100)
      messages = get_messages!(queue)

      expect messages |> to(be_empty())
    end

    it "should consume a message and nack it" do
      exchange = Examples.Error.config()[:exchange][:name]
      queue = Examples.Error.config()[:queue][:name]
      routing_key = Examples.Error.config()[:binding_options][:routing_key]

      publish!(exchange, routing_key, %{foo: :bar})
      :timer.sleep(100)
      messages = get_messages!(queue)

      expect messages |> to(be_empty())
    end
  end
end
