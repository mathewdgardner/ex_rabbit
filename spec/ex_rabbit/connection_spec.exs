defmodule ExRabbit.ConnectionSpec do
  use ESpec
  import Mock

  describe "ExRabbit.Connection" do
    it "should connect to RabbitMQ" do
      conn = :sys.get_state(ExRabbit.Connection)

      expect conn |> to(be_struct AMQP.Connection)
    end

    it "should re-connect to RabbitMQ" do
      :ok = GenServer.stop(ExRabbit.Connection)
      :timer.sleep(1)
      conn = :sys.get_state(ExRabbit.Connection)

      expect conn |> to(be_struct AMQP.Connection)
    end

    it "should retry connecting to RabbitMQ on error" do
      with_mock AMQP.Connection, [open: fn(_url) -> {:error, "Made up reason"} end] do
        url = ExRabbit.Connection.url()
        :ok = GenServer.stop(ExRabbit.Connection)
        :timer.sleep(Application.get_env(:ex_rabbit, :backoff) + 1)

        expect called(AMQP.Connection.open(url)) |> to(be_true())
      end
    end

    it "should get the connection" do
      conn = GenServer.call(ExRabbit.Connection, :get)

      expect conn |> to(be_struct AMQP.Connection)
    end
  end
end
