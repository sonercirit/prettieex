defmodule EexFormatter do
  @moduledoc """
  Documentation for `EexFormatter`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> EexFormatter.hello()
      :world

  """
  def hello do
    :world
  end

  def is_doctype(tag) do
    String.contains?(tag, "<!")
  end
end
