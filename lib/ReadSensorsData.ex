defmodule ReadSensorsData do
  use GenServer
  @tick_time 10000

  def start_link(sensor_name) do
    worker_name = String.to_atom("#{__MODULE__}_#{sensor_name}")
    GenServer.start_link(__MODULE__, %{sensor_name: sensor_name, messages: []}, name: worker_name)
  end

  def init(state) do
    consume()
    tick()
    {:ok, state}
  end

  defp tick, do: Process.send_after(self(), :tick, @tick_time)

  def consume() do
    IO.puts("Consuming message")

    case AMQP.Connection.open() do
      {:ok, connection} ->
        case AMQP.Channel.open(connection) do
          {:ok, channel} ->
            AMQP.Exchange.declare(channel, "macbook_sensors", :fanout)
            {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
            AMQP.Queue.bind(channel, queue_name, "macbook_sensors")
            AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)
            IO.puts(" [*] Waiting for messages")

          {:error, reason} ->
            {:stop, {:channel_open_error, reason}}
        end

      {:error, reason} ->
        {:stop, {:connection_open_error, reason}}
    end
  end

  def handle_info({:basic_deliver, payload, _meta}, state) do
    message = Jason.decode!(payload)

    if message["name"] == state.sensor_name do
      IO.inspect(message)
      {:noreply, %{state | messages: [message | state.messages]}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:basic_consume_ok, _payload}, state) do
    {:noreply, state}
  end

  def handle_info(:tick, %{messages: []} = state) do
    IO.puts("No messages to process for sensor: #{state.sensor_name}")

    tick()
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
