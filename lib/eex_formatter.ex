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
    tag |> String.contains?("<!")
  end

  def generate_placeholder do
    :crypto.strong_rand_bytes(10) |> Base.encode32()
  end

  def clean_eex(tag, placeholder) do
    tag |> String.replace(~r/<%.*?%>/s, placeholder)
  end

  def get_attributes(tag) do
    tag |> Floki.parse_document!()
  end

  def tokenize(tag) do
    {:ok, result} = tag |> EEx.Tokenizer.tokenize(1)
    result
  end
end
