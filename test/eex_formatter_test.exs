defmodule EexFormatterTest do
  use ExUnit.Case
  doctest EexFormatter

  test "greets the world" do
    assert EexFormatter.hello() == :world
  end

  test "detects doctype tag" do
    tag = "<!DOCTYPE hmtl>"
    assert tag |> EexFormatter.is_doctype() === true
  end

  test "returns false for normal tag" do
    tag = "<div>"
    assert tag |> EexFormatter.is_doctype() === false
  end

  test "clean eex" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"
    placeholder = EexFormatter.generate_placeholder()

    assert tag |> EexFormatter.clean_eex(placeholder) ===
             "<link rel=\"stylesheet\" href=\"#{placeholder}\"/>"
  end

  test "parses html" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    assert tag |> EexFormatter.clean_eex("1") |> EexFormatter.get_attributes() === [
             {"link", [{"rel", "stylesheet"}, {"href", "1"}], []}
           ]
  end

  test "tokenize tags" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    assert EexFormatter.tokenize(tag) === [
             {:text, '<link rel="stylesheet" href="'},
             {:expr, 1, '=', ' Routes.static_path(@conn, "/css/app.css") ', false},
             {:text, '"/>'}
           ]
  end
end
