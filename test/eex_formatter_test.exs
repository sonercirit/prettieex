defmodule EexFormatterTest do
  use ExUnit.Case
  doctest EexFormatter

  test "greets the world" do
    assert EexFormatter.hello() == :world
  end

  test "detects doctype tag" do
    tag = "<!DOCTYPE hmtl>"
    assert EexFormatter.is_doctype(tag) === true
  end

  test "returns false for normal tag" do
    tag = "<div>"
    assert EexFormatter.is_doctype(tag) === false
  end

  test "should clean eex" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"
    placeholder = EexFormatter.generate_placeholder()

    assert EexFormatter.clean_eex(tag, placeholder) ===
             "<link rel=\"stylesheet\" href=\"#{placeholder}\"/>"
  end

  test "parses html" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    assert EexFormatter.clean_eex(tag, "1") |> EexFormatter.get_attributes() === [
             {"link", [{"rel", "stylesheet"}, {"href", "1"}], []}
           ]
  end
end
