defmodule Sensors.Repo.Migrations.CreateSensorsData do
  use Ecto.Migration

  def change do
    create table(:sensors_data) do
      add :sensor_name, :string
      add :sensor_unit, :string
      add :sensor_mean_value, :float
      add :sensor_count_value, :integer
      add :sensor_peak_value, :float
      add :insert_date_time, :naive_datetime
    end

    create table(:anomaly_data) do
      add :flag_high_cpu_usage, :boolean
      add :flag_high_gpu_usage, :boolean
      add :insert_date_time, :naive_datetime
    end
  end
end
