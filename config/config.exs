import Config

config :rabbit_iot, Friends.Repo,
  database: "rabbit_iot_repo",
  username: "postgres",
  password: "iloveactors",
  hostname: "localhost"

config :rabbit_iot, ecto_repos: [Friends.Repo]
