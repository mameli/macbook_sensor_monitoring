defmodule ThrottlingDetector do
  require Ecto.Query
  use GenServer
  require Logger

  @time_window 10 * 60
  @peak_cpu_threshold 500
  @high_cpu_usage_threshold 300

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

    sd_list =
      Sensors.SensorData
      |> Ecto.Query.where([sd], sd.insert_date_time > ^window_start_time)
      |> Sensors.Repo.all()

    %{count: count, sum: sum, peak: peak} =
      sd_list
      |> Enum.reduce(%{sum: 0, count: 0, peak: 0}, fn sd, acc ->
        %{
          sum: acc.sum + sd.sensor_mean_value,
          count: acc.count + 1,
          peak: max(acc.peak, sd.sensor_peak_value)
        }
      end)

    mean = sum / count

    if mean > @high_cpu_usage_threshold or peak > @peak_cpu_threshold do
      Logger.info("High CPU usage detected")

      ad = %Sensors.AnomalyData{
        flag_high_cpu_usage: true,
        flag_high_gpu_usage: false,
        insert_date_time: latest_insert_time
      }

      Sensors.Repo.insert(ad)
    end

    tick()
    {:noreply, %{messages: []}}
  end

  defp tick, do: Process.send_after(self(), :tick, @time_window)
end
