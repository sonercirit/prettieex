defmodule Mix.Tasks.Prettieex do
  @moduledoc false
  use Mix.Task

  def run(args) do
    args |> List.first() |> EexFormatter.process_file()
  end
end
