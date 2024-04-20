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

  def connect do
    IO.puts "Connecting to RabbitMQ"
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    {connection, channel}
  end

  def declare_queue(channel) do
    IO.puts "Declaring queue"
    AMQP.Queue.declare(channel, "hello")
  end

  def publish(channel, msg) do
    IO.puts "Publishing message"
    AMQP.Basic.publish(channel, "", "hello", msg)
  end

  use GenServer
  require Logger

  # GenServer API
  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    {:ok, content} = File.read(".env")
    [_, pwd] = String.split(content, "=")
    command = "echo #{pwd} | sudo -k -S powermetrics -s cpu_power"
    Port.open({:spawn, command}, [:binary, :exit_status])

    {:ok, %{latest_output: nil, exit_status: nil} }
  end

  # This callback handles data incoming from the command's STDOUT
  def handle_info({_, {:data, text_line}}, state) do
    latest_output = text_line |> String.trim
    filtered_output = latest_output
    |> String.split("\n")
    |> Enum.filter(fn line -> String.starts_with?(line, "CPU Power:") end)

    Logger.info "Latest output: #{filtered_output}"

    {:noreply, %{state | latest_output: latest_output}}
  end

  def handle_info({_, {:exit_status, status}}, state) do
    Logger.info "External exit: :exit_status: #{status}"

    _ = %{state | exit_status: status}
    {:noreply, %{state | exit_status: status}}
  end
end
