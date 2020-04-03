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

  def process_file(name) do
    placeholder = generate_placeholder()
    result = name |> File.read!() |> clean_eex(placeholder) |> parse_html() |> prettify_html()

    name |> File.write!(result)
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

  def parse_html(tag) do
    tag |> Floki.parse_document!()
  end

  def generate_spaces(0) do
    ""
  end

  def generate_spaces(len) do
    1..len |> Enum.reduce("", fn _, acc -> acc <> " " end)
  end

  def prettify_attributes(attributes, indention) do
    spaces = indention |> generate_spaces()

    attributes
    |> Enum.reduce("", fn attribute, attr_acc ->
      {tag, value} = attribute
      "#{attr_acc}\n#{spaces}#{tag}=\"#{value}\""
    end)
  end

  def prettify_tag({tag, attributes, children}, acc) do
    {indention, curr} = acc
    spaces = indention |> generate_spaces()

    result = "#{spaces}<#{tag}"

    result =
      if !(attributes === []) do
        attributes = attributes |> prettify_attributes(indention + 2)
        result <> attributes <> "\n" <> spaces
      else
        result
      end

    result =
      if children === [] do
        "#{result}/>\n"
      else
        children = children |> prettify_html(indention + 2)
        "#{result}>\n#{children}#{spaces}</#{tag}>\n"
      end

    {indention, curr <> result}
  end

  def prettify_tag(text, acc) do
    {indention, curr} = acc
    spaces = indention |> generate_spaces()
    text = text |> String.trim()
    {indention, "#{curr}#{spaces}#{text}\n"}
  end

  def prettify_html(_, indention \\ 0)

  def prettify_html(parsed, indention) do
    {_, result} =
      parsed
      |> Enum.reduce({indention, ""}, fn element, acc ->
        element |> prettify_tag(acc)
      end)

    result
  end

  def tokenize(tag) do
    {:ok, result} = tag |> EEx.Tokenizer.tokenize(1)
    result
  end
end
