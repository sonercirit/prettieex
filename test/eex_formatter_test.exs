defmodule EExFormatterTest do
  use ExUnit.Case
  doctest EExFormatter

  defp sanitize_prettify_expression(expressions) do
    expressions |> Enum.map(fn x -> x <> "\n" end)
  end

  test "detects doctype tag" do
    tag = "<!DOCTYPE hmtl>"
    assert tag |> EExFormatter.is_doctype() === true
  end

  test "returns false for normal tag" do
    tag = "<div>"
    assert tag |> EExFormatter.is_doctype() === false
  end

  test "clean eex" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"
    placeholder = EExFormatter.generate_placeholder()

    assert tag |> EExFormatter.clean_eex(placeholder) ===
             "<link rel=\"stylesheet\" href=\"#{placeholder}\"/>"
  end

  test "parses html" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    assert tag |> EExFormatter.clean_eex("1") |> EExFormatter.parse_html() ===
             {nil, [{"link", [{"rel", "stylesheet"}, {"href", "1"}], []}]}
  end

  test "generate spaces for indention" do
    assert 10 |> EExFormatter.generate_spaces() === "          "
  end

  test "generate empty string for 0 spaces" do
    assert 0 |> EExFormatter.generate_spaces() === ""
  end

  test "prettify simple tag with not attributes" do
    tag = "<head></head>"

    assert tag |> EExFormatter.parse_html() |> EExFormatter.prettify_html() === """
           <head/>
           """
  end

  test "prettify html without eex" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    parsed = tag |> EExFormatter.clean_eex("1") |> EExFormatter.parse_html()

    assert parsed |> EExFormatter.prettify_html() === """
           <link
            rel="stylesheet"
            href="1"/>
           """
  end

  test "prettify html with children without eex" do
    tag = """
    <a href="https://phoenixframework.org/" class="phx-logo">
      <img src="<%= Routes.static_path(@conn, "/images/phoenix.png") %>" alt="Phoenix Framework Logo"/>
    </a>
    """

    parsed = tag |> EExFormatter.clean_eex("1") |> EExFormatter.parse_html()
    prettified = parsed |> EExFormatter.prettify_html()

    assert prettified === """
           <a
            href="https://phoenixframework.org/"
            class="phx-logo">
             <img
              src="1"
              alt="Phoenix Framework Logo"/>
           </a>
           """
  end

  test "prettify multiple nested html" do
    html = """
    <section class="container"><nav role="navigation"><ul><li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li></ul></nav><a href="https://phoenixframework.org/" class="phx-logo"><img src="<%= Routes.static_path(@conn, "/images/phoenix.png") %>" alt="Phoenix Framework Logo"/></a></section>
    """

    parsed = html |> EExFormatter.clean_eex("1") |> EExFormatter.parse_html()
    prettified = parsed |> EExFormatter.prettify_html()

    assert prettified === """
           <section
            class="container">
             <nav
              role="navigation">
               <ul>
                 <li>
                   <a
                    href="https://hexdocs.pm/phoenix/overview.html">
                     Get Started
                   </a>
                 </li>
               </ul>
             </nav>

             <a
              href="https://phoenixframework.org/"
              class="phx-logo">
               <img
                src="1"
                alt="Phoenix Framework Logo"/>
             </a>
           </section>
           """
  end

  test "keep !DOCTYPE if in first line" do
    html = """
    <!DOCTYPE html><html lang="en"/>
    """

    parsed = html |> EExFormatter.clean_eex("1") |> EExFormatter.parse_html()
    prettified = parsed |> EExFormatter.prettify_html()

    assert prettified === """
           <!DOCTYPE html>
           <html
            lang="en"/>
           """
  end

  test "tokenize tags" do
    tag = "<link rel=\"stylesheet\" href=\"<%= Routes.static_path(@conn, \"/css/app.css\") %>\"/>"

    assert tag |> EExFormatter.tokenize() === [
             {:text, '<link rel="stylesheet" href="'},
             {:expr, 1, '=', ' Routes.static_path(@conn, "/css/app.css") ', false},
             {:text, '"/>'}
           ]
  end

  test "find expressions in tokenized data" do
    html = """
    <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
    <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
    <%= render @view_module, @view_template, assigns %>
    """

    assert html |> EExFormatter.tokenize() |> EExFormatter.get_expressions() === [
             {:expr, 1, '=', ' get_flash(@conn, :info) ', false},
             {:expr, 2, '=', ' get_flash(@conn, :error) ', false},
             {:expr, 3, '=', ' render @view_module, @view_template, assigns ', false}
           ]
  end

  test "get correct expressions for different types of eex syntax" do
    expr = """
    <% "1" %>
    <%= "2" %>
    <%% "3" %>
    <%# "4" %>
    """

    assert expr |> EExFormatter.tokenize() |> EExFormatter.get_expressions() === [
             {:expr, 1, [], ' "1" ', false},
             {:expr, 2, '=', ' "2" ', false}
           ]
  end

  test "clean correct expressions for different types of eex syntax" do
    html = """
    <p class="alert alert-info" role="alert">
    <% "1" %>
    <%= "2" %>
    <%% "3" %>
    <%# "4" %>
    </p>
    <p class="alert alert-danger" role="alert"><%= get_flash @conn, :error %></p>
    <% "1" %>
    <%= "2" %>
    <%% "3" %>
    <%# "4" %>
    """

    assert html
           |> EExFormatter.clean_eex()
           |> EExFormatter.parse_html()
           |> EExFormatter.prettify_html() === """
           <p
            class="alert alert-info"
            role="alert">
             <placeholder/>

             <placeholder/>

             <%% "3" %> <%# "4" %>
           </p>

           <p
            class="alert alert-danger"
            role="alert">
             <placeholder/>
           </p>

           <placeholder/>

           <placeholder/>

           <%% "3" %> <%# "4" %>
           """
  end

  test "prettify tokenized expressions" do
    html = """
    <p class="alert alert-info" role="alert"><%= get_flash @conn, :info %></p>
    <p class="alert alert-danger" role="alert"><%= get_flash @conn, :error %></p>
    <%= render @view_module, @view_template, assigns %>
    """

    tokens = html |> EExFormatter.tokenize()
    formattable_string = tokens |> EExFormatter.generate_formattable_string()

    assert tokens
           |> EExFormatter.get_expressions()
           |> EExFormatter.prettify_expressions(formattable_string) === [
             "<%= get_flash(@conn, :info) %>",
             "<%= get_flash(@conn, :error) %>",
             "<%= render(@view_module, @view_template, assigns) %>"
           ]
  end

  test "prettify multi-line expression" do
    expr = "<%= if true do true else false end %>"

    tokens = expr |> EExFormatter.tokenize()
    formattable_string = tokens |> EExFormatter.generate_formattable_string()

    assert tokens
           |> EExFormatter.get_expressions()
           |> EExFormatter.prettify_expressions(formattable_string)
           |> sanitize_prettify_expression() === [
             """
             <%=
               if true do
                 true
               else
                 false
               end
             %>
             """
           ]
  end

  test "squish multi-line text" do
    html = """
    <p>
    A productive web framework that
    <br/>
    does not compromise speed <%# comment: here %>
    or               maintainability.
    </p>
    """

    assert html |> EExFormatter.parse_html() |> EExFormatter.prettify_html() === """
           <p>
             A productive web framework that

             <br/>

             does not compromise speed <%# comment: here %> or maintainability.
           </p>
           """
  end

  test "ignore empty string" do
    html = """
    <body><script type="text/javascript" src="<%= Routes.static_path(@conn, "/js/app.js") %>"></script></body>
    """

    assert html
           |> EExFormatter.clean_eex()
           |> EExFormatter.parse_html()
           |> EExFormatter.prettify_html() === """
           <body>
             <script
              type="text/javascript"
              src="<placeholder/>"/>
           </body>
           """
  end

  test "replace formatted expressions with placeholders" do
    html = """
    <p class="alert alert-info" role="<%= true %>"><%= get_flash @conn, :info %></p>
    <p class="alert alert-danger" role="alert"><%= get_flash @conn, :error %></p>
    <% render @view_module, @view_template, assigns %>
    """

    tokens = html |> EExFormatter.tokenize()
    formattable_string = tokens |> EExFormatter.generate_formattable_string()

    expressions =
      tokens
      |> EExFormatter.get_expressions()
      |> EExFormatter.prettify_expressions(formattable_string)

    assert html
           |> EExFormatter.clean_eex()
           |> EExFormatter.parse_html()
           |> EExFormatter.prettify_html()
           |> EExFormatter.replace_expressions(expressions) === """
           <p
            class="alert alert-info"
            role="<%= true %>">
             <%= get_flash(@conn, :info) %>
           </p>

           <p
            class="alert alert-danger"
            role="alert">
             <%= get_flash(@conn, :error) %>
           </p>

           <% render(@view_module, @view_template, assigns) %>
           """
  end

  test "replace multi-line expression with placeholder" do
    html = """
    <p class="alert alert-info" role="<%= if true do "exp1" else false end %>"><% if true do "exp2" else false end %></p>
    """

    tokens = html |> EExFormatter.tokenize()
    formattable_string = tokens |> EExFormatter.generate_formattable_string()

    expressions =
      tokens
      |> EExFormatter.get_expressions()
      |> EExFormatter.prettify_expressions(formattable_string)

    assert html
           |> EExFormatter.clean_eex()
           |> EExFormatter.parse_html()
           |> EExFormatter.prettify_html()
           |> EExFormatter.replace_expressions(expressions) === """
           <p
            class="alert alert-info"
            role="<%=
                    if true do
                      "exp1"
                    else
                      false
                    end
                  %>">
             <%
               if true do
                 "exp2"
               else
                 false
               end
             %>
           </p>
           """
  end

  test "generate string espaced html for feeding to formatter" do
    html = """
    <div>
    <section>
    <%= case {1, 2, 3} do %>
      <% {4, 5, 6} -> %>
        This clause won't match
      <% {1, x, 3} -> %>
        <%= if true do %>
        <% y = 1 + 2 + 3 %>
        This clause will match and bind x to 2 in this clause
        <% else %>
        Never do this
        <% end %>
      <% _ -> %>
        This clause would match any value
    <% end %>
    </section>
    </div>
    """

    assert html
           |> EExFormatter.tokenize()
           |> EExFormatter.generate_formattable_string()
           |> Code.format_string!()
  end

  test "get scattered expressions" do
    html = """
    <div>
    <section>
    <%= case {1, 2, 3} do %>
      <% {4, 5, 6} -> %>
        This clause won't match
      <% {1, x, 3} -> %>
        <%= if true do %>
        <% y = 1 + 2 + 3 %>
        This clause will match and bind x to 2 in this clause
        <% else %>
        Never do this
        <% end %>
      <% _ -> %>
        This clause would match any value
    <% end %>
    </section>
    </div>
    """

    assert html
           |> EExFormatter.tokenize()
           |> EExFormatter.get_expressions() === [
             {:start_expr, 3, '=', ' case {1, 2, 3} do ', false},
             {:middle_expr, 4, [], ' {4, 5, 6} -> ', false},
             {:middle_expr, 6, [], ' {1, x, 3} -> ', false},
             {:start_expr, 7, '=', ' if true do ', false},
             {:expr, 8, [], ' y = 1 + 2 + 3 ', false},
             {:middle_expr, 10, [], ' else ', false},
             {:end_expr, 12, [], ' end ', false},
             {:middle_expr, 13, [], ' _ -> ', false},
             {:end_expr, 15, [], ' end ', false}
           ]
  end

  test "prettifies scattered expressions" do
    html = """
    <div>
    <section>
    <%= case {1, 2, 3} do %>
      <% {4, 5, 6} -> %>
        This clause won't match
      <% {1,x,3} -> %>
        <%= if true do %>
        <% y = 1+2+ 3 %>
        This clause will match and bind x to 2 in this clause
        <% else %>
        Never do this
        <% end %>
      <% _ -> %>
        This clause would match any value
    <% end %>
    <%= IO.puts "a" %>
    </section>
    </div>
    """

    tokens = html |> EExFormatter.tokenize()
    formattable_string = tokens |> EExFormatter.generate_formattable_string()

    assert tokens
           |> EExFormatter.get_expressions()
           |> EExFormatter.prettify_expressions(formattable_string) === [
             "<%= case {1, 2, 3} do %>",
             "<% {4, 5, 6} -> %>",
             "<% {1, x, 3} -> %>",
             "<%= if true do %>",
             "<% y = 1 + 2 + 3 %>",
             "<% else %>",
             "<% end %>",
             "<% _ -> %>",
             "<% end %>",
             "<%= IO.puts(\"a\") %>"
           ]
  end

  test "one-line multiline attributes" do
    html = """
    <div class="a
    b"/>
    """

    assert html |> EExFormatter.parse_html() |> EExFormatter.prettify_html() === """
           <div
            class="a b"/>
           """
  end

  test "clear extra spaces from attributes" do
    html = """
    <div class="a
                b"/>
    """

    assert html |> EExFormatter.parse_html() |> EExFormatter.prettify_html() === """
           <div
            class="a b"/>
           """
  end

  test "prettifies html with scattered expressions" do
    html = """
    <div>
    <section>
    <%= case {1, 2, 3} do %>
      <% {4, 5, 6} -> %>
        This clause won't match
      <% {1,x,3} -> %>
        <%= if true do %>
        <% y = 1+2+ 3 %>
        This clause will match and bind x to 2 in this clause
        <% else %>
        Never do this
        <% end %>
      <% _ -> %>
        This clause would match any value
    <% end %>
    <%= IO.puts "a" %>
    </section>
    </div>
    """

    result = html |> EExFormatter.process_string()

    assert result === """
           <div>
             <section>
               <%= case {1, 2, 3} do %>

               <% {4, 5, 6} -> %>

               This clause won't match

               <% {1, x, 3} -> %>

               <%= if true do %>

               <% y = 1 + 2 + 3 %>

               This clause will match and bind x to 2 in this clause

               <% else %>

               Never do this

               <% end %>

               <% _ -> %>

               This clause would match any value

               <% end %>

               <%= IO.puts("a") %>
             </section>
           </div>
           """
  end

  test "handle html comments" do
    html = "<!-- very important commentary -->\n"

    assert html |> EExFormatter.parse_html() |> EExFormatter.prettify_html() === html
  end

  test "html with comments" do
    html = """
    <div>some text</div>
    <!-- very important commentary -->
    <div>some other text</div>
    """

    assert html |> EExFormatter.parse_html() |> EExFormatter.prettify_html() === """
           <div>
             some text
           </div>

           <!-- very important commentary -->

           <div>
             some other text
           </div>
           """
  end
end
