defmodule Ironman.MixProject do
  use Mix.Project

  def project do
    [
      app: :ironman,
      version: "0.1.2",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/TheFirstAvenger/ironman",
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: true
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, "priv/plts/ironman.plt"},
        plt_add_apps: [:mix]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
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
      {:git_hooks, "~> 0.2.0", only: :test},
      {:excoveralls, "~> 0.10.5", only: :test},
      {:credo, "~> 1.0.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19.3", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.9.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.3.1", only: :dev, runtime: false},
      {:mox, "~> 0.4.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/TheFirstAvenger/ironman"}
    ]
  end

  defp description do
    "Automated project configuration with Elixir best practices"
  end
end
