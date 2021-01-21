# PandaDoc

This package implements the [PandaDoc.com](https://pandadoc.com) API for digitally signing documents with Elixir.

If you need more of their API, just launch a Pull Request.

## Installation

This package can be installed by adding `pandadoc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pandadoc, "~> 0.1.2"}
  ]
end
```

## Configuration

Put the following lines into your `config.exs` or better, into your environment configuration files like `test.exs`, `dev.exs` or `prod.exs.`.

```elixir
config :pandadoc, api_key: "<your api key>"
```

## Documentation

Documentation can be found at [https://hexdocs.pm/pandadoc](https://hexdocs.pm/pandadoc).
