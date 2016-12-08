defmodule PostgrexCache.Mixfile do
  use Mix.Project

  def project do
    [app: :postgrex_cache,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :postgrex, :poolboy],
     mod: {PostgrexCache, []}]
  end

  defp deps do
    [{:postgrex, "~> 1.0.0-rc"},
     {:poolboy, "~> 1.5.1"}]
  end
end
