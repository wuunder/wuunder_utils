defmodule WuunderUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :wuunder_utils,
      deps: deps(),
      description: "Set of helper modules",
      dialyzer: dialyzer_config(),
      docs: docs(),
      elixir: "~> 1.14",
      name: "Wuunder Utils",
      organization: "wuunder",
      package: package(),
      source_url: "https://github.com/wuunder/wuunder_utils",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.html": :test],
      version: "0.6.3"
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
      {:credo, "~> 1.3", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ecto, "~> 3.11"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.0", only: :test}
    ]
  end

  defp package do
    [
      name: "wuunder_utils",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/wuunder/wuunder_utils",
        "Docs" => "https://hexdocs.pm/wuunder_utils"
      }
    ]
  end

  defp docs do
    [
      main: "WuunderUtils",
      extras: ["README.md"]
    ]
  end

  defp dialyzer_config do
    [
      plt_add_apps: [:mix, :ex_unit],
      plt_file: {:no_warn, "priv/plts/project.plt"},
      format: :dialyxir,
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      flags: ["-Wunmatched_returns", :error_handling, :underspecs]
    ]
  end
end
