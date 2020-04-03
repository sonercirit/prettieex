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

  def generate_placeholder do
    :crypto.strong_rand_bytes(10) |> Base.encode32()
  end

  def clean_eex(tag, placeholder) do
    tag |> String.replace(~r/<%.*?%>/s, placeholder)
  end

  def get_attributes(tag) do
    Floki.parse_document!(tag)
  end
end
