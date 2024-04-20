defmodule Consumer do
  use GenServer

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    consume()
    tick()
    {:ok, %{messages: []}}
  end

  defp tick, do: Process.send_after(self(), :tick, 60000)

  def consume() do
    IO.puts "Consuming message"

    case AMQP.Connection.open() do
      {:ok, connection} ->
        case AMQP.Channel.open(connection) do
          {:ok, channel} ->
            AMQP.Queue.declare(channel, "macbook_sensors")
            AMQP.Basic.consume(channel, "macbook_sensors", nil, no_ack: true)
            IO.puts " [*] Waiting for messages. To exit press CTRL+C, CTRL+C"
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
    {:noreply, Map.update!(state, :messages, &([decoded_payload | &1]))}
  end

  def handle_info({:basic_consume_ok, _payload}, state) do
    {:noreply, state}
  end

  def handle_info(:tick, state) do
    IO.puts("Printing...")
    IO.inspect(state.messages)
    tick()
    {:noreply, %{state | messages: []}}
  end
end
