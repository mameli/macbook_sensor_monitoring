defmodule Sensors.SensorData do
  use Ecto.Schema

  schema "sensors_data" do
    field :sensor_name, :string
    field :sensor_unit, :string
    field :sensor_mean_value, :float
    field :sensor_count_value, :integer
    field :sensor_peak_value, :float
    field :insert_date_time, :naive_datetime
  end
end
