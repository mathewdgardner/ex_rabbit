defmodule ExRabbit.ConsumerSpec do
  use ESpec

  describe "ExRabbit.Consumer" do
    it "should have a consumer for each module" do
      count = Supervisor.count_children(ExRabbit.Consumer).workers
      modules = Application.get_env(:ex_rabbit, :modules)

      expect length(modules) |> to(eql(count))

      Supervisor.which_children(ExRabbit.Consumer)
        |> Enum.map(fn ({id, _pid, _type, [module]}) ->
          expect modules |> to(have(id))
          expect module |> to(eql(ExRabbit.Consumer.Consumer))
        end)
    end
  end
end
