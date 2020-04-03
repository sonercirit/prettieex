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
end
