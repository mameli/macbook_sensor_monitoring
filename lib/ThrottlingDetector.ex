defmodule ThrottlingDetector do
  require Ecto.Query
  use GenServer
  require Logger

  @minutes 5 * 60 # 5 minutes in seconds
  @tick_time 1000 * @minutes # 5 minutes in milliseconds
  @time_window @minutes # 5 minutes in seconds
  @peak_cpu_threshold 100
  @high_cpu_usage_threshold 800
  @peak_gpu_threshold 500
  @high_gpu_usage_threshold 300

  # GenServer API
  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args \\ []) do
    tick()
    {:ok, %{messages: []}}
  end

  def handle_info(:tick, _) do
    latest_sensor_data = Sensors.SensorData |> Ecto.Query.last() |> Sensors.Repo.one()

    latest_insert_time = latest_sensor_data.insert_date_time
    window_start_time = NaiveDateTime.add(latest_insert_time, -@time_window)

    cpu_power_aggregated_data =
      fetch_sensor_data("CPU Power", window_start_time) |> aggregate_sensor_data()

    gpu_power_aggregated_data =
      fetch_sensor_data("GPU Power", window_start_time) |> aggregate_sensor_data()

    cpu_mean = cpu_power_aggregated_data.sum / cpu_power_aggregated_data.count
    gpu_mean = gpu_power_aggregated_data.sum / gpu_power_aggregated_data.count

    check_list = [
      cpu_mean > @high_cpu_usage_threshold,
      cpu_power_aggregated_data.peak > @peak_cpu_threshold,
      gpu_mean > @high_gpu_usage_threshold,
      gpu_power_aggregated_data.peak > @peak_gpu_threshold
    ]

    if Enum.any?(check_list) do
      Logger.info("High usage detected")

      ad = %Sensors.AnomalyData{
        flag_high_cpu_usage:
          cpu_mean > @high_cpu_usage_threshold ||
            cpu_power_aggregated_data.peak > @peak_cpu_threshold,
        flag_high_gpu_usage:
          gpu_mean > @high_gpu_usage_threshold ||
            gpu_power_aggregated_data.peak > @peak_gpu_threshold,
        insert_date_time: latest_insert_time
      }

      Logger.info("Anomaly data: cpu #{inspect(cpu_power_aggregated_data)}, gpu #{inspect(gpu_power_aggregated_data)}")

      Sensors.Repo.insert(ad)
    end

    tick()
    {:noreply, %{messages: []}}
  end

  defp tick, do: Process.send_after(self(), :tick, @tick_time)

  defp fetch_sensor_data(sensor_name, window_start_time) do
    Sensors.SensorData
    |> Ecto.Query.where([sd], sd.insert_date_time > ^window_start_time)
    |> Ecto.Query.where([sd], sd.sensor_name == ^sensor_name)
    |> Sensors.Repo.all()
  end

  defp aggregate_sensor_data(sensor_data_list) do
    Enum.reduce(sensor_data_list, %{count: 0, sum: 0, peak: 0}, fn sd, acc ->
      value = sd.sensor_mean_value
      peak = sd.sensor_peak_value
      %{count: acc.count + 1, sum: acc.sum + value, peak: max(acc.peak, peak)}
    end)
  end
end
