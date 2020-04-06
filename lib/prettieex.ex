defmodule Mix.Tasks.Prettieex do
  @moduledoc false
  use Mix.Task

  def run(args) do
    path = args |> List.first()

    path =
      if path === nil do
        "lib/**/*.html.eex"
      else
        path
      end

    path
    |> Path.expand()
    |> Path.wildcard()
    |> Enum.reduce([], fn file, acc ->
      [
        Task.async(fn ->
          file |> EExFormatter.process_file()
        end)
        | acc
      ]
    end)
    |> Enum.each(fn task ->
      task |> Task.await()
    end)
  end
end
