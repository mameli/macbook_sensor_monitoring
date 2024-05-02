defmodule RabbitIot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Sensors.Repo,
      # {GenSensorsData, []},
      # Supervisor.child_spec({ReadSensorsData, "CPU Power"}, id: :consumer_1),
      # Supervisor.child_spec({ReadSensorsData, "GPU Power"}, id: :consumer_2),
      # ThrottlingDetector
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RabbitIot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
