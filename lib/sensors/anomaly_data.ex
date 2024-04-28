defmodule Sensors.AnomalyData do
  use Ecto.Schema

  schema "anomaly_data" do
    field :flag_high_cpu_usage, :boolean
    field :flag_high_gpu_usage, :boolean
    field :insert_date_time, :naive_datetime
  end
end
