defmodule Mix.Tasks.Prettieex do
  @moduledoc false
  use Mix.Task

  def run(args) do
    [path | _] = args
    abspath = path |> Path.expand()
    Path.wildcard(abspath) |> Enum.each(fn file -> file |> EExFormatter.process_file() end)
  end
end
