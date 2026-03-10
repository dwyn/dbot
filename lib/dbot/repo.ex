defmodule Dbot.Repo do
  use Ecto.Repo,
    otp_app: :dbot,
    adapter: Ecto.Adapters.Postgres
end
