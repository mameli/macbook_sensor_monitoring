defmodule GenSensorsData do
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
            AMQP.Exchange.declare(channel, "macbook_sensors", :fanout)

            {:ok, content} = File.read(".env")
            [_, pwd] = String.split(content, "=")
            command = "echo #{pwd} | sudo -k -S powermetrics -s cpu_power, gpu_power"
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
      |> Enum.filter(fn line ->
        String.starts_with?(line, "CPU Power:") or String.starts_with?(line, "GPU Power")
      end)

    case filtered_output do
      ["CPU Power: " <> cpu_power, "GPU Power: " <> gpu_power | _] ->
        cpu_data = extract_value(cpu_power) |> create_json("CPU Power", "mW")
        gpu_data = extract_value(gpu_power) |> create_json("GPU Power", "mW")

        IO.inspect(cpu_data)
        IO.inspect(gpu_data)

        AMQP.Basic.publish(channel, "macbook_sensors", "", cpu_data)
        AMQP.Basic.publish(channel, "macbook_sensors", "", gpu_data)

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

  defp extract_value(power_string) do
    power_string
    |> String.trim()
    |> String.split(" ")
    |> List.first()
  end

  defp create_json(power_string_value, name, unit) do
    json = %{
      name: name,
      unit: unit,
      value: power_string_value
    }

    {:ok, data} = Jason.encode(json)
    data
  end
end
