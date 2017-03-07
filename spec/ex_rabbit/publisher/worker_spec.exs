defmodule ExRabbit.Publisher.WorkerSpec do
  use ESpec

  describe "ExRabbit.Publisher.Worker" do

    it "should hold a channel" do
      channel = ExRabbit.Application.via({:publisher, 1})
        |> :sys.get_state

      expect channel |> to(be_struct AMQP.Channel)
    end
  end
end
