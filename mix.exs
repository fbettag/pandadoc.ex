defmodule PandaDoc.MixProject do
  use Mix.Project

  @project_url "https://github.com/fbettag/pandadoc.ex"

  def project do
    [
      app: :pandadoc,
      version: "0.1.0",
      elixir: "~> 1.10",
      source_url: @project_url,
      homepage_url: @project_url,
      name: "pandadoc.com API",
      description:
        "This package implements the free document signing API provided by pandadoc.com",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      name: "pandadoc",
      maintainers: ["Franz Bettag"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:poison, "~> 4.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, github: "rrrene/credo", only: [:dev, :test]},
      {:doctor, "~> 0.17.0", only: :dev},
      {:git_hooks, "~> 0.4.0", only: [:test, :dev], runtime: false}
    ]
  end
end
