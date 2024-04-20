CREATE SCHEMA sensors;

CREATE TABLE sensors.grouped_sensor_data (
  sensor_name VARCHAR(255),
  sensor_unit VARCHAR(255),
  sensor_mean_value FLOAT,
  sensor_count_value INTEGER,
  sensor_peak_value FLOAT,
  insert_date_time TIMESTAMP
);

CREATE TABLE sensors.anomaly_data (
  flag_high_cpu_usage BOOLEAN,
  flag_high_gpu_usage BOOLEAN,
  insert_date_time TIMESTAMP
);