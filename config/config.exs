import Config

config :rabbit_iot, Sensors.Repo,
  database: "rabbit_iot_repo",
  username: "postgres",
  password: "iloveactors",
  hostname: "localhost"

config :rabbit_iot, ecto_repos: [Sensors.Repo]
