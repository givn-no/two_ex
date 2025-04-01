defmodule Two.MixProject do
  use Mix.Project

  def project do
    [
      app: :two_ex,
      version: "0.0.2",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      hex: hex(),
      deps: deps(),
      name: "Two Client",
      source_url: "https://github.com/hooplab/two_ex"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4.3"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.2"}
    ]
  end

  defp description() do
    "An elixir SDK built on Tesla for interacting with Nets Easy's payment API, not official nor endorsed by NETS."
  end

  defp package() do
    [
      name: "two_ex",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/givn-no/two_ex"}
    ]
  end

  defp hex do
    [
      api_url: System.get_env("HEX_API_URL"),
      api_key: System.get_env("HEX_API_KEY")
    ]
  end
end
