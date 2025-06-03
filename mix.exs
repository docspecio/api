defmodule DocSpec.MixProject do
  use Mix.Project

  @name "DocSpec"
  @description "DocSpec Conversion API"

  def project do
    [
      app: :docspec,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer_config(Mix.env()),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      test_coverage: [tool: ExCoveralls],

      # Docs and publishing
      name: @name,
      description: @description,
      docs: &docs/0,
      package: package()
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  def package do
    [
      files: [
        "lib/",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ]
    ]
  end

  def dialyzer_config(:test), do: [plt_add_apps: [:ex_unit]]
  def dialyzer_config(_), do: []

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {DocSpec.Application, []}
    ]
  end

  defp deps do
    [
      {:nldoc_spec, "~> 3.1"},
      {:nldoc_util, "~> 1.0"},
      {:nldoc_conversion_reader_docx, "~> 1.1"},

      # Defining data structures
      {:typed_struct, "~> 0.3.0"},

      # Logging
      {:logger_json, "~> 7.0"},

      # HTTP Server for Plug
      {:phoenix, "~> 1.7"},
      {:bandit, "~> 1.0"},

      # JSON Parsing
      {:jason, "~> 1.4"},

      # Testing: coverage, JUnit-style test reports for CI, mocking and snapshot testing.
      {:nldoc_test, "~> 3.0", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:mimic, "~> 1.10", only: :test},

      # Linting & do
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Dependency auditing
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Docs
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end
end
