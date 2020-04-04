defmodule EExFormatter do
  @moduledoc false

  def process_file(name) do
    html = name |> File.read!()

    expressions =
      html
      |> EExFormatter.tokenize()
      |> EExFormatter.get_expressions()
      |> EExFormatter.prettify_expressions()

    result =
      html |> clean_eex() |> parse_html() |> prettify_html() |> replace_expressions(expressions)

    name |> File.write!(result)
  end

  def is_doctype(tag) do
    tag |> String.contains?("<!")
  end

  def generate_placeholder do
    :crypto.strong_rand_bytes(10) |> Base.encode32()
  end

  def clean_eex(tag, placeholder \\ "<placeholder/>") do
    tag |> String.replace(~r/<%[^#|%].*?%>/s, placeholder)
  end

  def parse_html(html) do
    doctype = ~r/<!doctype (.*?)>/is |> Regex.run(html)

    doctype =
      if doctype === nil do
        nil
      else
        doctype |> List.last()
      end

    html = html |> Floki.parse_document!()

    {doctype, html}
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
        result <> attributes
      else
        result
      end

    result =
      if children === [] do
        "#{result}/>\n"
      else
        children = {nil, children} |> prettify_html(indention + 2)
        "#{result}>\n#{children}#{spaces}</#{tag}>\n"
      end

    {indention, curr <> result}
  end

  def prettify_tag("", acc) do
    acc
  end

  def prettify_tag(text, acc) do
    {indention, curr} = acc
    spaces = indention |> generate_spaces()

    text =
      text
      |> String.trim()
      |> String.replace(~r/[^\S ]/s, " ")
      |> String.replace(~r/  +/s, " ")

    {indention, "#{curr}#{spaces}#{text}\n"}
  end

  def prettify_html({doctype, parsed}, indention \\ 0) do
    initial =
      if doctype === nil do
        ""
      else
        "<!DOCTYPE #{doctype}>\n"
      end

    {_, result} =
      parsed
      |> Enum.reduce({indention, initial}, fn element, acc ->
        element |> prettify_tag(acc)
      end)

    result
  end

  def tokenize(html) do
    {:ok, result} = html |> EEx.Tokenizer.tokenize(1)
    result
  end

  def is_expression({:expr, _, _, _, _}) do
    true
  end

  def is_expression(_) do
    false
  end

  def get_expressions(tokens) do
    tokens |> Enum.filter(fn token -> token |> is_expression() end)
  end

  def get_expression_pre_suff('=') do
    {"<%=", "%>"}
  end

  def get_expression_pre_suff([]) do
    {"<%", "%>"}
  end

  def is_multiline_expression(expression) do
    if expression |> String.contains?("\n") do
      true
    else
      false
    end
  end

  def prettify_expressions(expressions) do
    expressions
    |> Enum.map(fn expression ->
      {pre, suff} = expression |> elem(2) |> get_expression_pre_suff()

      prettified_expression =
        expression |> elem(3) |> to_string() |> Code.format_string!() |> Enum.join()

      if prettified_expression |> is_multiline_expression() do
        prettified_expression = prettified_expression |> String.replace("\n", "\n  ")
        "#{pre}\n  #{prettified_expression}\n#{suff}"
      else
        "#{pre} #{prettified_expression} #{suff}"
      end
    end)
  end

  def get_expression([head | tail]) do
    [head | tail]
  end

  def get_expression([]) do
    ["" | []]
  end

  def append_spaces_to_multiline_expression(spaces, expression) do
    splits =
      expression
      |> String.split("\n")

    [head | tail] = splits

    tail
    |> Enum.reduce(head, fn split, acc ->
      "#{acc}\n#{spaces}#{split}"
    end)
  end

  def replace_expression(split, acc) do
    {curr, expressions} = acc
    [expression | tail] = expressions |> get_expression()

    expression =
      if expression |> is_multiline_expression() do
        split
        |> String.graphemes()
        |> Enum.reverse()
        |> Enum.find_index(fn x -> x === "\n" end)
        |> generate_spaces()
        |> append_spaces_to_multiline_expression(expression)
      else
        expression
      end

    {"#{curr}#{split}#{expression}", tail}
  end

  def replace_expressions(html, expressions) do
    {result, _} =
      html
      |> String.split("<placeholder/>")
      |> Enum.reduce({"", expressions}, fn split, acc ->
        split |> replace_expression(acc)
      end)

    result
  end
end
