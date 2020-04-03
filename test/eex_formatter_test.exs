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

    assert tag |> EexFormatter.clean_eex("1") |> EexFormatter.parse_html() === [
             {"link", [{"rel", "stylesheet"}, {"href", "1"}], []}
           ]
  end

  test "generate spaces for indention" do
    assert 10 |> EexFormatter.generate_spaces() === "          "
  end

  test "generate empty string for 0 spaces" do
    assert 0 |> EexFormatter.generate_spaces() === ""
  end

  test "prettify simple tag with not attributes" do
    tag = "<head></head>"

    assert tag |> EexFormatter.parse_html() |> EexFormatter.prettify_html() === """
           <head/>
           """
  end

  test "prettify html without eex" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    parsed = tag |> EexFormatter.clean_eex("1") |> EexFormatter.parse_html()

    assert parsed |> EexFormatter.prettify_html() === """
           <link
             rel="stylesheet"
             href="1"
           />
           """
  end

  test "prettify html with children without eex" do
    tag = """
    <a href="https://phoenixframework.org/" class="phx-logo">
      <img src="<%= Routes.static_path(@conn, "/images/phoenix.png") %>" alt="Phoenix Framework Logo"/>
    </a>
    """

    parsed = tag |> EexFormatter.clean_eex("1") |> EexFormatter.parse_html()
    prettified = parsed |> EexFormatter.prettify_html()

    assert prettified === """
           <a
             href="https://phoenixframework.org/"
             class="phx-logo"
           >
             <img
               src="1"
               alt="Phoenix Framework Logo"
             />
           </a>
           """
  end

  test "prettify multiple nested html" do
    html = """
    <section class="container"><nav role="navigation"><ul><li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li></ul></nav><a href="https://phoenixframework.org/" class="phx-logo"><img src="<%= Routes.static_path(@conn, "/images/phoenix.png") %>" alt="Phoenix Framework Logo"/></a></section>
    """

    parsed = html |> EexFormatter.clean_eex("1") |> EexFormatter.parse_html()
    prettified = parsed |> EexFormatter.prettify_html()

    IO.puts("\n" <> prettified)

    assert prettified === """
           <section
             class="container"
           >
             <nav
               role="navigation"
             >
               <ul>
                 <li>
                   <a
                     href="https://hexdocs.pm/phoenix/overview.html"
                   >
                     Get Started
                   </a>
                 </li>
               </ul>
             </nav>
             <a
               href="https://phoenixframework.org/"
               class="phx-logo"
             >
               <img
                 src="1"
                 alt="Phoenix Framework Logo"
               />
             </a>
           </section>
           """
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
