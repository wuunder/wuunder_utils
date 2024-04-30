defmodule WuunderUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :wuunder_utils,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        # The main page in the docs
        main: "WuunderUtils",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.11"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
