defmodule ThrottlingDetector do
  require Ecto.Query
  use GenServer
  require Logger

  @time_window 10 * 60
  @threshold 100

  # GenServer API
  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    tick()
    {:ok, %{messages: []}}
  end

  def handle_info(:tick, _) do
    latest_sensor_data = Sensors.SensorData |> Ecto.Query.last |> Sensors.Repo.one

    latest_insert_time = latest_sensor_data.insert_date_time
    window_start_time = NaiveDateTime.add(latest_insert_time, -@time_window)

    IO.inspect(latest_insert_time, window_start_time)

    tick()
    {:noreply, %{messages: []}}
  end

  def query_sensor_data() do
    latest_sensor_data = Sensors.SensorData |> Ecto.Query.last |> Sensors.Repo.one

    latest_insert_time = latest_sensor_data.insert_date_time
    window_start_time = NaiveDateTime.add(latest_insert_time, -@time_window)

    sd_list = Sensors.SensorData
    |> Ecto.Query.where([sd], sd.insert_date_time > ^window_start_time)
    |> Sensors.Repo.all()

    %{count: count, sum: sum} = sd_list |> Enum.reduce(%{sum: 0, count: 0}, fn sd, acc ->
      %{sum: acc.sum + sd.sensor_mean_value, count: acc.count + 1}
    end)

    mean = sum / count

    if mean > @threshold do
      Logger.info("High CPU usage detected")
    end

    sd_list |> Enum.any?(fn sd -> sd.sensor_peak_value > @threshold end) && Logger.info("Throttling detected")


  end

  defp tick, do: Process.send_after(self(), :tick, @time_window)
end
