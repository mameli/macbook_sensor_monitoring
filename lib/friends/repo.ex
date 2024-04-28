defmodule Friends.Repo do
  use Ecto.Repo,
    otp_app: :rabbit_iot,
    adapter: Ecto.Adapters.Postgres
end
