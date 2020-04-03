defmodule Mix.Tasks.Prettieex do
  @moduledoc false
  use Mix.Task

  def run(args) do
    args |> List.first() |> EExFormatter.process_file()
  end
end
