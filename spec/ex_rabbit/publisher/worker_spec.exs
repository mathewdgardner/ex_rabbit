defmodule ExRabbit.Publisher.WorkerSpec do
  use ESpec

  describe "ExRabbit.Publisher.Worker" do

    it "should hold a channel" do
      channel = :sys.get_state(ExRabbit.Publisher.Worker_1)

      expect channel |> to(be_struct AMQP.Channel)
    end
  end
end
