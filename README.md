# PrettiEEx

Prettifies EEx HTML files in an opinionated way. Prettifies both the HTML and the embedded Elixir code.

## Usage

Just run prettieex
```elixir
mix prettieex
```
and it will prettify all the .html.eex files under lib directory.

The only allowed parameter is the path, for example:
```elixir
mix prettieex "lib/**/*.html.eex"
```

### **DISCLAIMER:** This is not ready for production use. Use at your own risk.

## Installation

The package can be installed by adding `prettieex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prettieex, github: "sonercirit/prettieex", ref: "master", only: :dev}
  ]
end
```
