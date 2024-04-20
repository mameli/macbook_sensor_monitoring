defmodule RabbitIot.MixProject do
  use Mix.Project

  def project do
    [
      app: :rabbit_iot,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [applications: [:amqp]]
  end

  defp deps() do
    [
      {:amqp, "~> 3.3"},
      {:jason, "~> 1.2"}
    ]
  end
end
