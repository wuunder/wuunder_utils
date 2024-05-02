defmodule WuunderUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :wuunder_utils,
      version: "0.2.6",
      elixir: "~> 1.14",
      organization: "wuunder",
      name: "Wuunder Utils",
      description: "Set of helper modules",
      package: package(),
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
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ecto, "~> 3.11"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "wuunder_utils",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/wuunder/wuunder_utils"}
    ]
  end
end
