defmodule ReadSensorsData do
  use GenServer

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    consume()
    tick()
    {:ok, %{messages: []}}
  end

  defp tick, do: Process.send_after(self(), :tick, 10000)

  def consume() do
    IO.puts("Consuming message")

    case AMQP.Connection.open() do
      {:ok, connection} ->
        case AMQP.Channel.open(connection) do
          {:ok, channel} ->
            AMQP.Queue.declare(channel, "macbook_sensors")
            AMQP.Basic.consume(channel, "macbook_sensors", nil, no_ack: true)
            IO.puts(" [*] Waiting for messages. To exit press CTRL+C, CTRL+C")

          {:error, reason} ->
            {:stop, {:channel_open_error, reason}}
        end

      {:error, reason} ->
        {:stop, {:connection_open_error, reason}}
    end
  end

  def handle_info({:basic_deliver, payload, _meta}, state) do
    decoded_payload = Jason.decode!(payload)
    IO.inspect(decoded_payload)
    {:noreply, Map.update!(state, :messages, &[decoded_payload | &1])}
  end

  def handle_info({:basic_consume_ok, _payload}, state) do
    {:noreply, state}
  end

  def handle_info(:tick, state) do
    aggregated_data =
      Enum.reduce(state.messages, %{sum: 0, count: 0, peak: 0}, fn message, acc ->
        value =
          case Float.parse(message["value"]) do
            {value, ""} ->
              value

            _ ->
              IO.puts("Invalid float: #{message["value"]}")
              0.0
          end

        %{sum: acc.sum + value, count: acc.count + 1, peak: max(acc.peak, value)}
      end)

    aggregated_data = Map.put(aggregated_data, :mean, aggregated_data.sum / aggregated_data.count)

    sd = %Sensors.SensorData{
      sensor_name: state.messages |> List.first() |> Map.get("name"),
      sensor_unit: state.messages |> List.first() |> Map.get("unit"),
      sensor_mean_value: aggregated_data.mean,
      sensor_count_value: aggregated_data.count,
      sensor_peak_value: aggregated_data.peak,
      insert_date_time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    IO.inspect(sd)

    Sensors.Repo.insert(sd)

    tick()
    {:noreply, %{state | messages: []}}
  end
end
