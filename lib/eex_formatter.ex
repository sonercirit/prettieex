defmodule EExFormatter do
  @moduledoc false

  def process_file(name) do
    html = name |> File.read!()

    tokens = html |> EExFormatter.tokenize()
    formattable_string = tokens |> EExFormatter.generate_formattable_string()

    expressions =
      tokens
      |> EExFormatter.get_expressions()
      |> EExFormatter.prettify_expressions(formattable_string)

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

  def clean_extra_whitespace(arg) do
    arg |> String.replace(~r/\s+/s, " ")
  end

  def prettify_attributes(attributes, spaces) do
    attributes
    |> Enum.reduce("", fn attribute, attr_acc ->
      {tag, value} = attribute
      tag = tag |> clean_extra_whitespace()
      value = value |> clean_extra_whitespace()
      "#{attr_acc}\n#{spaces}#{tag}=\"#{value}\""
    end)
  end

  def get_prepend(index) do
    if index === 0 do
      ""
    else
      "\n"
    end
  end

  def prettify_tag({{tag, attributes, children}, index}, acc, indention) do
    spaces = indention |> generate_spaces()

    prepend = index |> get_prepend()
    result = "#{prepend}#{spaces}<#{tag}"

    result =
      if attributes === [] do
        result
      else
        attributes = attributes |> prettify_attributes(spaces <> " ")
        result <> attributes
      end

    result =
      if children === [] || children === [""] do
        "#{result}/>\n"
      else
        children = {nil, children} |> prettify_html(indention + 2)
        "#{result}>\n#{children}#{spaces}</#{tag}>\n"
      end

    acc <> result
  end

  def prettify_tag({text, index}, acc, indention) do
    spaces = indention |> generate_spaces()
    prepend = index |> get_prepend()

    text =
      text
      |> String.trim()
      |> String.replace(~r/[^\S ]/s, " ")
      |> String.replace(~r/  +/s, " ")

    "#{acc}#{prepend}#{spaces}#{text}\n"
  end

  def prettify_html({doctype, parsed}, indention \\ 0) do
    initial =
      if doctype === nil do
        ""
      else
        "<!DOCTYPE #{doctype}>\n"
      end

    parsed
    |> Enum.with_index()
    |> Enum.reduce(initial, fn element, acc ->
      element |> prettify_tag(acc, indention)
    end)
  end

  def tokenize(html) do
    {:ok, result} = html |> EEx.Tokenizer.tokenize(1)
    result
  end

  def is_expression({:text, _}) do
    false
  end

  def is_expression(_) do
    true
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

  def prettify_expressions(expressions, formattable_string) do
    formatted_string = formattable_string |> Code.format_string!() |> Enum.join()

    expressions
    |> Enum.map(fn expression ->
      {pre, suff} = expression |> elem(2) |> get_expression_pre_suff()

      regex =
        expression
        |> elem(3)
        |> to_string()
        |> String.replace(~r/\s/, "")
        |> String.graphemes()
        |> Enum.reduce("", fn letter, acc ->
          acc <> (letter |> Regex.escape()) <> "[\\s|(|)]*?"
        end)

      regex = ~r/(.*)\[\\s\|\(\|\)\]\*/ |> Regex.run(regex) |> Enum.at(1)
      regex = (regex <> "\\)?") |> Regex.compile!()

      [prettified_expression | _] = regex |> Regex.run(formatted_string)

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

  def get_token_details({:text, text}) do
    {:text, text}
  end

  def get_token_details({type, _, _, text, _}) do
    {type, text}
  end

  def generate_text(token, acc) do
    {type, text} = token |> get_token_details()
    text = text |> to_string() |> String.trim()

    case type do
      :text ->
        if text === "" do
          acc
        else
          text = text |> String.replace("\"", "\\\"")
          acc <> "\n\"" <> text <> "\""
        end

      _ ->
        acc <> "\n" <> text
    end
  end

  def generate_formattable_string(tokens) do
    tokens
    |> Enum.reduce("", fn token, acc ->
      token |> generate_text(acc)
    end)
  end
end
