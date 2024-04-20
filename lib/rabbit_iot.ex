defmodule RabbitIot do
  @moduledoc """
  Documentation for `RabbitIot`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RabbitIot.hello()
      :world

  """
  def hello do
    :world
  end

  use GenServer
  require Logger

  # GenServer API
  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    IO.puts("Connecting to RabbitMQ")

    case AMQP.Connection.open() do
      {:ok, connection} ->
        case AMQP.Channel.open(connection) do
          {:ok, channel} ->
            AMQP.Queue.declare(channel, "macbook_sensors")

            {:ok, content} = File.read(".env")
            [_, pwd] = String.split(content, "=")
            command = "echo #{pwd} | sudo -k -S powermetrics -s cpu_power"
            Port.open({:spawn, command}, [:binary, :exit_status])

            {:ok, %{latest_output: nil, exit_status: nil, channel: channel}}

          {:error, reason} ->
            {:stop, {:channel_open_error, reason}}
        end

      {:error, reason} ->
        {:stop, {:connection_open_error, reason}}
    end
  end

  def handle_info({_, {:data, text_line}}, %{channel: channel} = state) do
    latest_output = text_line |> String.trim()

    filtered_output =
      latest_output
      |> String.split("\n")
      |> Enum.filter(fn line -> String.starts_with?(line, "CPU Power:") end)

    case filtered_output do
      [line | _] ->
        value = String.split(line, ":") |> List.last() |> String.trim()

        json = %{
          name: "CPU Power",
          unit: "mW",
          value: value
        }

        {:ok, data} = Jason.encode(json)

        AMQP.Basic.publish(channel, "", "macbook_sensors", data)
      _ ->
        # Handle case when filtered_output is empty or doesn't contain the expected line
        IO.puts("No CPU Power data found")
    end

    {:noreply, %{state | latest_output: latest_output}}
  end

  def handle_info({_, {:exit_status, status}}, state) do
    Logger.info("External exit: :exit_status: #{status}")

    _ = %{state | exit_status: status}
    {:noreply, %{state | exit_status: status}}
  end
end
