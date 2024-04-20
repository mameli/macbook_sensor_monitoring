defmodule Consumer do
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

  def wait_for_messages do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts " [x] Received #{payload}"
        wait_for_messages()
    end
  end
end
